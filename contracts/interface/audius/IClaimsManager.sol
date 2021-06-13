pragma solidity ^0.6.2;

interface IClaimsManager {
    /// @notice Get the duration of a funding round in blocks
    function getFundingRoundBlockDiff() external view returns (uint256);

    /// @notice Get the last block where a funding round was initiated
    function getLastFundedBlock() external view returns (uint256);

    /// @notice Get the amount funded per round in wei
    function getFundsPerRound() external view returns (uint256);

    /// @notice Get the total amount claimed in the current round
    function getTotalClaimedInRound() external view returns (uint256);

    /// @notice Get the Governance address
    function getGovernanceAddress() external view returns (address);

    /// @notice Get the ServiceProviderFactory address
    function getServiceProviderFactoryAddress() external view returns (address);

    /// @notice Get the DelegateManager address
    function getDelegateManagerAddress() external view returns (address);

    /**
     * @notice Get the Staking address
     */
    function getStakingAddress() external view returns (address);

    /**
     * @notice Get the community pool address
     */
    function getCommunityPoolAddress() external view returns (address);

    /**
     * @notice Get the community funding amount
     */
    function getRecurringCommunityFundingAmount() external view returns (uint256);

    /**
     * @notice Set the Governance address
     * @dev Only callable by Governance address
     * @param _governanceAddress - address for new Governance contract
     */
    function setGovernanceAddress(address _governanceAddress) external;

    /**
     * @notice Set the Staking address
     * @dev Only callable by Governance address
     * @param _stakingAddress - address for new Staking contract
     */
    function setStakingAddress(address _stakingAddress) external;

    /**
     * @notice Set the ServiceProviderFactory address
     * @dev Only callable by Governance address
     * @param _serviceProviderFactoryAddress - address for new ServiceProviderFactory contract
     */
    function setServiceProviderFactoryAddress(address _serviceProviderFactoryAddress) external;

    /**
     * @notice Set the DelegateManager address
     * @dev Only callable by Governance address
     * @param _delegateManagerAddress - address for new DelegateManager contract
     */
    function setDelegateManagerAddress(address _delegateManagerAddress) external;

    /**
     * @notice Start a new funding round
     * @dev Permissioned to be callable by stakers or governance contract
     */
    function initiateRound() external;

    /**
     * @notice Mints and stakes tokens on behalf of ServiceProvider + delegators
     * @dev Callable through DelegateManager by Service Provider
     * @param _claimer  - service provider address
     * @param _totalLockedForSP - amount of tokens locked up across DelegateManager + ServiceProvider
     * @return minted rewards for this claimer
     */
    function processClaim(address _claimer, uint256 _totalLockedForSP) external returns (uint256);

    /**
     * @notice Modify funding amount per round
     * @param _newAmount - new amount to fund per round in wei
     */
    function updateFundingAmount(uint256 _newAmount) external;

    /**
     * @notice Returns boolean indicating whether a claim is considered pending
     * @dev Note that an address with no endpoints can never have a pending claim
     * @param _sp - address of the service provider to check
     * @return true if eligible for claim, false if not
     */
    function claimPending(address _sp) external view returns (bool);

    /**
     * @notice Modify minimum block difference between funding rounds
     * @param _newFundingRoundBlockDiff - new min block difference to set
     */
    function updateFundingRoundBlockDiff(uint256 _newFundingRoundBlockDiff) external;

    /**
     * @notice Modify community funding amound for each round
     * @param _newRecurringCommunityFundingAmount - new reward amount transferred to
     *          communityPoolAddress at funding round start
     */
    function updateRecurringCommunityFundingAmount(uint256 _newRecurringCommunityFundingAmount) external;

    /**
     * @notice Modify community pool address
     * @param _newCommunityPoolAddress - new address to which recurringCommunityFundingAmount
     *          is transferred at funding round start
     */
    function updateCommunityPoolAddress(address _newCommunityPoolAddress) external;
}
