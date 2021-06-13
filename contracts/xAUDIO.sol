pragma solidity ^0.6.2;

import "./interface/audius/IClaimsManager.sol";
import "./interface/audius/IDelegateManager.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

/// @title xAUDIO.
/// @author Oozyx.
/// @notice xAUDIO is a yield generating ERC20 wrapper for the AUDIO token.
contract xAUDIO is Initializable, ERC20UpgradeSafe, OwnableUpgradeSafe, PausableUpgradeSafe {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Structs
    struct FeeStructure {
        uint256 mintFee;
        uint256 claimFee;
    }

    // Constants
    uint256 internal constant AUDIO_STAKING_PERCENTAGE = 95;
    uint256 private constant MAX_UINT = 2**256 - 1;

    // Internal members to be initialized at time of construction
    IClaimsManager internal audioClaimsManager;
    IDelegateManager internal audioDelegateManager;
    IERC20 internal audioToken;
    FeeStructure internal feeStructure;

    // Internal members
    mapping(address => uint256) internal serviceProviderStakedAmount;
    uint256 internal withdrawableAudioTokenFees;
    uint256 internal stakedAudioTokenFees;
    uint256 internal totalStakedAmount;

    /// @notice Initializes the contract.
    /// @param _name The token name.
    /// @param _symbol The token symbol.
    /// @param _audioToken The address to the ERC20 AUDIO token.
    /// @param _mintFee The minting fee (ppc i.e. 1 = 0.001%).
    /// @param _claimFee The claiming fee (ppc i.e. 1 = 0.001%).
    function initialize(
        string calldata _name,
        string calldata _symbol,
        IClaimsManager _audioClaimsManager,
        IDelegateManager _audioDelegateManager,
        IERC20 _audioToken,
        uint256 _mintFee,
        uint256 _claimFee
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC20_init_unchained(_name, _symbol);

        audioClaimsManager = _audioClaimsManager;
        audioDelegateManager = _audioDelegateManager;
        audioToken = _audioToken;

        // Approve the staking contract to handle AUDIO tokens
        audioToken.approve(audioDelegateManager.getStakingAddress(), MAX_UINT);

        feeStructure.mintFee = _mintFee;
        feeStructure.claimFee = _claimFee;
    }

    /* ========================================================================================= */
    /*                                      User Interaction                                     */
    /* ========================================================================================= */

    /// @notice Mints the xToken by wrapping the sender's AUDIO token.
    /// @param _tokenAmount The amount of tokens the sender wishes to be wrapped.
    function mintWithToken(uint256 _tokenAmount) external whenNotPaused {
        require(_tokenAmount > 0, "Must send token.");
        require(audioToken.balanceOf(msg.sender) >= _tokenAmount, "Sender does not have enough tokens.");

        audioToken.safeTransferFrom(msg.sender, address(this), _tokenAmount);

        uint256 audioTokenFee = calculateFee(_tokenAmount, feeStructure.mintFee);
        withdrawableAudioTokenFees = withdrawableAudioTokenFees.add(audioTokenFee);

        _xAUDIOTokenMint(_tokenAmount.sub(audioTokenFee));
    }

    function _xAUDIOTokenMint(uint256 _audioTokenAmount) private {
        // TODO: currently xToken to AUDIO is 1 to 1. implement logic similar to xINCH
        _mint(msg.sender, _audioTokenAmount);
    }

    /* ========================================================================================= */
    /*                                            Management                                     */
    /* ========================================================================================= */

    /// @notice Stakes the AUDIO tokens in the contract to maintain a ratio of staked/buffered.
    /// @dev AUDIO_STAKING_PERCENTAGE represents the target percentage of staked tokens.
    /// @param _serviceProvider The service provide to delegate audio tokens to.
    /// @param _amount The amount to stake.
    function stake(address _serviceProvider, uint256 _amount) external whenNotPaused onlyOwner {
        // Note: stake transaction won't go through for the following conditions:
        // - "DelegateManager: Delegation not permitted for SP pending claim"
        // - "DelegateManager: Maximum delegators exceeded"

        // Verify what is the current percentage of staked vs buffered AUDIO tokens
        require(
            getCurrentStakedPercentage() < AUDIO_STAKING_PERCENTAGE,
            "Cannot stake need to keep staked/buffered ratio."
        );

        // Stake the newStake amount, delegateStake returns the updated totalAmount
        serviceProviderStakedAmount[_serviceProvider] = audioDelegateManager.delegateStake(_serviceProvider, _amount);
        totalStakedAmount = totalStakedAmount.add(_amount);
    }

    /// @notice Claims the staking rewards that get added to current stake.
    /// @param _serviceProvider The service provider with our staked tokens.
    function claimRewards(address _serviceProvider) external whenNotPaused onlyOwner {
        // Initiate a round
        // Note: Will fail if the following condition is met:
        // - "ClaimsManager: Required block difference not met"
        audioClaimsManager.initiateRound();

        // Check stake amount before and after claim
        uint256 stakeBeforeClaim = audioDelegateManager.getDelegatorStakeForServiceProvider(
            address(this),
            _serviceProvider
        );
        audioDelegateManager.claimRewards(_serviceProvider);
        uint256 stakeAfterClaim = audioDelegateManager.getDelegatorStakeForServiceProvider(
            address(this),
            _serviceProvider
        );

        // New stake amount
        uint256 stakeAmountChange = stakeAfterClaim.sub(stakeBeforeClaim);

        // Apply the fee
        uint256 claimFee = calculateFee(stakeAmountChange, feeStructure.claimFee);

        // Update the balances
        totalStakedAmount = totalStakedAmount.add(stakeAmountChange);
        serviceProviderStakedAmount[_serviceProvider] = serviceProviderStakedAmount[_serviceProvider].add(
            stakeAmountChange
        );
        stakedAudioTokenFees = stakedAudioTokenFees.add(claimFee);
    }

    /// @notice Activates the cooldown period to unstake tokens.
    /// @param _serviceProvider The address of the service provider with the delegated tokens.
    /// @param _amount The token amount to undelegate from the service provider.
    function cooldown(address _serviceProvider, uint256 _amount) external whenNotPaused onlyOwner {
        // Note: _audioDelegateManager performs all the necessary checks for validating a cooldown request
        // - "DelegateManager: Requested undelegate stake amount must be greater than zero"
        // - "DelegateManager: Undelegate request not permitted for SP pending claim"
        // - "DelegateManager: No pending lockup expected"
        // - "DelegateManager: Cannot decrease greater than currently staked for this ServiceProvider"

        // Get the current stake for the given service provider
        // Current stake might be less than what we originally staked because the service provider may have been slashed
        uint256 currentStake = audioDelegateManager.getDelegatorStakeForServiceProvider(
            address(this),
            _serviceProvider
        );

        // Request to undelegate and verify if the operation was successful
        uint256 updatedStake = audioDelegateManager.requestUndelegateStake(_serviceProvider, _amount);
        require(currentStake.sub(updatedStake) == _amount, "Error requesting unstaking provided amount.");
    }

    /// @notice Unstakes if there's a pending undelegation requests that has reached the end of its lockup period.
    /// @dev There's no need to specify a provider because only one request for undelegation can be made at a time.
    ///      Also no need to specify token amount because that was specified at the time of the cooldown request.
    function unstake() external whenNotPaused onlyOwner {
        // Note: _audioDelegateManager performs all the necessary checks for validating an unstaking call
        // - "DelegateManager: Pending lockup expected"
        // - "DelegateManager: Lockup must be expired"
        // - "DelegateManager: Undelegate not permitted for SP pending claim"

        (address serviceProvider, uint256 amount, ) = audioDelegateManager.getPendingUndelegateRequest(address(this));
        serviceProviderStakedAmount[serviceProvider] = audioDelegateManager.undelegateStake();

        // Update the staked balance
        totalStakedAmount = totalStakedAmount.sub(amount);

        // Update the fee balances
        if (amount >= stakedAudioTokenFees) {
            withdrawableAudioTokenFees = withdrawableAudioTokenFees.add(stakedAudioTokenFees);
            stakedAudioTokenFees = 0;
        } else {
            withdrawableAudioTokenFees = withdrawableAudioTokenFees.add(amount);
            stakedAudioTokenFees = stakedAudioTokenFees.sub(amount);
        }
    }

    /// @notice Withdraws the management fees
    function withdrawFees() external whenNotPaused onlyOwner {
        require(withdrawableAudioTokenFees > 0, "Cannot withdraw 0 fees.");

        audioToken.safeTransfer(msg.sender, withdrawableAudioTokenFees);

        withdrawableAudioTokenFees = 0;
    }

    /* ========================================================================================= */
    /*                                        Getters                                            */
    /* ========================================================================================= */

    function getCurrentStakedPercentage() public view returns (uint256) {
        uint256 currentAudioBalance = audioToken.balanceOf(address(this)).sub(withdrawableAudioTokenFees);
        uint256 totalAudioAmount = currentAudioBalance.add(totalStakedAmount).sub(stakedAudioTokenFees);
        return totalStakedAmount.mul(100).div(totalAudioAmount);
    }

    function getTotalStakedAmount() public view returns (uint256) {
        return totalStakedAmount;
    }

    function getWithdrawableFees() public view returns (uint256) {
        return withdrawableAudioTokenFees;
    }

    function getStakedFees() public view returns (uint256) {
        return stakedAudioTokenFees;
    }

    function getStakedAmount(address _serviceProvider) public view returns (uint256) {
        return serviceProviderStakedAmount[_serviceProvider];
    }

    /* ========================================================================================= */
    /*                                        Getters                                            */
    /* ========================================================================================= */

    function calculateFee(uint256 _tokenAmount, uint256 _feeFraction) private pure returns (uint256) {
        return _tokenAmount.mul(_feeFraction).div(100000);
    }
}

// You should have five external functions:
//  - mintWithToken: accepts AUDIO and pays out proportional supply of xAUDIO
//  - stake: stakes AUDIO so that 95% of AUDIO balance in contract is staked and 5% is maintained as a buffer
//  - claimRewards: claims rewards from AUDIO contracts
//  - cooldown: this triggers Audius' 7 day cooldown period before you're able to unstake
//  - unstake: this takes an amount param and allows the admin to unstake that amount after the 7 day cooldown has elapsed
