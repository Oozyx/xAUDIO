pragma solidity ^0.6.2;

interface IDelegateManager {
    /**
     * @notice Allow a delegator to delegate stake to a service provider
     * @param _targetSP - address of service provider to delegate to
     * @param _amount - amount in wei to delegate
     * @return Updated total amount delegated to the service provider by delegator
     */
    function delegateStake(address _targetSP, uint256 _amount) external returns (uint256);

    /**
     * @notice Submit request for undelegation
     * @param _target - address of service provider to undelegate stake from
     * @param _amount - amount in wei to undelegate
     * @return Updated total amount delegated to the service provider by delegator
     */
    function requestUndelegateStake(address _target, uint256 _amount) external returns (uint256);

    /**
     * @notice Cancel undelegation request
     */
    function cancelUndelegateStakeRequest() external;

    /**
     * @notice Finalize undelegation request and withdraw stake
     * @return New total amount currently staked after stake has been undelegated
     */
    function undelegateStake() external returns (uint256);

    /**
     * @notice Claim and distribute rewards to delegators and service provider as necessary
     * @param _serviceProvider - Provider for which rewards are being distributed
     * @dev Factors in service provider rewards from delegator and transfers deployer cut
     */
    function claimRewards(address _serviceProvider) external;

    // ========================================= View Functions =========================================

    /**
     * @notice Get list of delegators for a given service provider
     * @param _sp - service provider address
     */
    function getDelegatorsList(address _sp) external view returns (address[] memory);

    /**
     * @notice Get total delegation from a given address
     * @param _delegator - delegator address
     */
    function getTotalDelegatorStake(address _delegator) external view returns (uint256);

    /// @notice Get total amount delegated to a service provider
    function getTotalDelegatedToServiceProvider(address _sp) external view returns (uint256);

    /// @notice Get total delegated stake locked up for a service provider
    function getTotalLockedDelegationForServiceProvider(address _sp) external view returns (uint256);

    /// @notice Get total currently staked for a delegator, for a given service provider
    function getDelegatorStakeForServiceProvider(address _delegator, address _serviceProvider)
        external
        view
        returns (uint256);

    /**
     * @notice Get status of pending undelegate request for a given address
     * @param _delegator - address of the delegator
     */
    function getPendingUndelegateRequest(address _delegator)
        external
        view
        returns (
            address target,
            uint256 amount,
            uint256 lockupExpiryBlock
        );

    /**
     * @notice Get status of pending remove delegator request for a given address
     * @param _serviceProvider - address of the service provider
     * @param _delegator - address of the delegator
     * @return - current lockup expiry block for remove delegator request
     */
    function getPendingRemoveDelegatorRequest(address _serviceProvider, address _delegator)
        external
        view
        returns (uint256);

    /// @notice Get current undelegate lockup duration
    function getUndelegateLockupDuration() external view returns (uint256);

    /// @notice Current maximum delegators
    function getMaxDelegators() external view returns (uint256);

    /// @notice Get minimum delegation amount
    function getMinDelegationAmount() external view returns (uint256);

    /// @notice Get the duration for remove delegator request lockup
    function getRemoveDelegatorLockupDuration() external view returns (uint256);

    /// @notice Get the duration for evaluation of remove delegator operations
    function getRemoveDelegatorEvalDuration() external view returns (uint256);

    /// @notice Get the Governance address
    function getGovernanceAddress() external view returns (address);

    /// @notice Get the ServiceProviderFactory address
    function getServiceProviderFactoryAddress() external view returns (address);

    /// @notice Get the ClaimsManager address
    function getClaimsManagerAddress() external view returns (address);

    /// @notice Get the Staking address
    function getStakingAddress() external view returns (address);
}
