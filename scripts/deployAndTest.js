// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require('hardhat');

// mainnet addresses
const ADDRESSES = {
    audioDelegateManager: '0x4d7968ebfD390D5E7926Cb3587C39eFf2F9FB225',
    audioClaimsManager: '0x44617f9dced9787c3b06a05b35b4c779a2aa1334',
    audioToken: '0x18aAA7115705e8be94bfFEBDE57Af9BFc265B998',
    serviceProviderEndlineNetwork: '0x528D6Fe7dF9356C8EabEC850B0f908F53075B382',
    serviceProviderHashbeam: '0x1BD9D60a0103FF2fA25169918392f118Bc616Dc9'
};

const AUDIO_TOKEN_ABI = [
    {
        anonymous: false,
        inputs: [
            { indexed: true, internalType: 'address', name: 'owner', type: 'address' },
            { indexed: true, internalType: 'address', name: 'spender', type: 'address' },
            { indexed: false, internalType: 'uint256', name: 'value', type: 'uint256' }
        ],
        name: 'Approval',
        type: 'event'
    },
    {
        anonymous: false,
        inputs: [{ indexed: true, internalType: 'address', name: 'account', type: 'address' }],
        name: 'MinterAdded',
        type: 'event'
    },
    {
        anonymous: false,
        inputs: [{ indexed: true, internalType: 'address', name: 'account', type: 'address' }],
        name: 'MinterRemoved',
        type: 'event'
    },
    {
        anonymous: false,
        inputs: [{ indexed: false, internalType: 'address', name: 'account', type: 'address' }],
        name: 'Paused',
        type: 'event'
    },
    {
        anonymous: false,
        inputs: [{ indexed: true, internalType: 'address', name: 'account', type: 'address' }],
        name: 'PauserAdded',
        type: 'event'
    },
    {
        anonymous: false,
        inputs: [{ indexed: true, internalType: 'address', name: 'account', type: 'address' }],
        name: 'PauserRemoved',
        type: 'event'
    },
    {
        anonymous: false,
        inputs: [
            { indexed: true, internalType: 'address', name: 'from', type: 'address' },
            { indexed: true, internalType: 'address', name: 'to', type: 'address' },
            { indexed: false, internalType: 'uint256', name: 'value', type: 'uint256' }
        ],
        name: 'Transfer',
        type: 'event'
    },
    {
        anonymous: false,
        inputs: [{ indexed: false, internalType: 'address', name: 'account', type: 'address' }],
        name: 'Unpaused',
        type: 'event'
    },
    {
        constant: true,
        inputs: [],
        name: 'DOMAIN_SEPARATOR',
        outputs: [{ internalType: 'bytes32', name: '', type: 'bytes32' }],
        payable: false,
        stateMutability: 'view',
        type: 'function'
    },
    {
        constant: true,
        inputs: [],
        name: 'PERMIT_TYPEHASH',
        outputs: [{ internalType: 'bytes32', name: '', type: 'bytes32' }],
        payable: false,
        stateMutability: 'view',
        type: 'function'
    },
    {
        constant: false,
        inputs: [{ internalType: 'address', name: 'account', type: 'address' }],
        name: 'addMinter',
        outputs: [],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: false,
        inputs: [{ internalType: 'address', name: 'account', type: 'address' }],
        name: 'addPauser',
        outputs: [],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: true,
        inputs: [
            { internalType: 'address', name: 'owner', type: 'address' },
            { internalType: 'address', name: 'spender', type: 'address' }
        ],
        name: 'allowance',
        outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
        payable: false,
        stateMutability: 'view',
        type: 'function'
    },
    {
        constant: false,
        inputs: [
            { internalType: 'address', name: 'spender', type: 'address' },
            { internalType: 'uint256', name: 'value', type: 'uint256' }
        ],
        name: 'approve',
        outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: true,
        inputs: [{ internalType: 'address', name: 'account', type: 'address' }],
        name: 'balanceOf',
        outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
        payable: false,
        stateMutability: 'view',
        type: 'function'
    },
    {
        constant: false,
        inputs: [{ internalType: 'uint256', name: 'amount', type: 'uint256' }],
        name: 'burn',
        outputs: [],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: false,
        inputs: [
            { internalType: 'address', name: 'account', type: 'address' },
            { internalType: 'uint256', name: 'amount', type: 'uint256' }
        ],
        name: 'burnFrom',
        outputs: [],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: true,
        inputs: [],
        name: 'decimals',
        outputs: [{ internalType: 'uint8', name: '', type: 'uint8' }],
        payable: false,
        stateMutability: 'view',
        type: 'function'
    },
    {
        constant: false,
        inputs: [
            { internalType: 'address', name: 'spender', type: 'address' },
            { internalType: 'uint256', name: 'subtractedValue', type: 'uint256' }
        ],
        name: 'decreaseAllowance',
        outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: false,
        inputs: [
            { internalType: 'address', name: 'spender', type: 'address' },
            { internalType: 'uint256', name: 'addedValue', type: 'uint256' }
        ],
        name: 'increaseAllowance',
        outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: false,
        inputs: [
            { internalType: 'string', name: 'name', type: 'string' },
            { internalType: 'string', name: 'symbol', type: 'string' },
            { internalType: 'uint8', name: 'decimals', type: 'uint8' }
        ],
        name: 'initialize',
        outputs: [],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: false,
        inputs: [
            { internalType: 'address', name: '_owner', type: 'address' },
            { internalType: 'address', name: 'governance', type: 'address' }
        ],
        name: 'initialize',
        outputs: [],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: false,
        inputs: [],
        name: 'initialize',
        outputs: [],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: false,
        inputs: [{ internalType: 'address', name: 'sender', type: 'address' }],
        name: 'initialize',
        outputs: [],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: true,
        inputs: [{ internalType: 'address', name: 'account', type: 'address' }],
        name: 'isMinter',
        outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
        payable: false,
        stateMutability: 'view',
        type: 'function'
    },
    {
        constant: true,
        inputs: [{ internalType: 'address', name: 'account', type: 'address' }],
        name: 'isPauser',
        outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
        payable: false,
        stateMutability: 'view',
        type: 'function'
    },
    {
        constant: false,
        inputs: [
            { internalType: 'address', name: 'account', type: 'address' },
            { internalType: 'uint256', name: 'amount', type: 'uint256' }
        ],
        name: 'mint',
        outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: true,
        inputs: [],
        name: 'name',
        outputs: [{ internalType: 'string', name: '', type: 'string' }],
        payable: false,
        stateMutability: 'view',
        type: 'function'
    },
    {
        constant: true,
        inputs: [{ internalType: 'address', name: '', type: 'address' }],
        name: 'nonces',
        outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
        payable: false,
        stateMutability: 'view',
        type: 'function'
    },
    {
        constant: false,
        inputs: [],
        name: 'pause',
        outputs: [],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: true,
        inputs: [],
        name: 'paused',
        outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
        payable: false,
        stateMutability: 'view',
        type: 'function'
    },
    {
        constant: false,
        inputs: [
            { internalType: 'address', name: 'owner', type: 'address' },
            { internalType: 'address', name: 'spender', type: 'address' },
            { internalType: 'uint256', name: 'value', type: 'uint256' },
            { internalType: 'uint256', name: 'deadline', type: 'uint256' },
            { internalType: 'uint8', name: 'v', type: 'uint8' },
            { internalType: 'bytes32', name: 'r', type: 'bytes32' },
            { internalType: 'bytes32', name: 's', type: 'bytes32' }
        ],
        name: 'permit',
        outputs: [],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: false,
        inputs: [],
        name: 'renounceMinter',
        outputs: [],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: false,
        inputs: [],
        name: 'renouncePauser',
        outputs: [],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: true,
        inputs: [],
        name: 'symbol',
        outputs: [{ internalType: 'string', name: '', type: 'string' }],
        payable: false,
        stateMutability: 'view',
        type: 'function'
    },
    {
        constant: true,
        inputs: [],
        name: 'totalSupply',
        outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
        payable: false,
        stateMutability: 'view',
        type: 'function'
    },
    {
        constant: false,
        inputs: [
            { internalType: 'address', name: 'to', type: 'address' },
            { internalType: 'uint256', name: 'value', type: 'uint256' }
        ],
        name: 'transfer',
        outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: false,
        inputs: [
            { internalType: 'address', name: 'from', type: 'address' },
            { internalType: 'address', name: 'to', type: 'address' },
            { internalType: 'uint256', name: 'value', type: 'uint256' }
        ],
        name: 'transferFrom',
        outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    },
    {
        constant: false,
        inputs: [],
        name: 'unpause',
        outputs: [],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function'
    }
];

async function main() {
    // Script Flow after deploying and initializing:
    // 1. User mints xAUDIO tokens with 500 AUDIO tokens
    // 2. Stake 100 AUDIO tokens to the Endline Network service provider
    // 3. Make claim for AUDIO staking rewards
    // 4. Cooldown initiated for unstaking
    // 5. Unstake tokens

    // Set up accounts
    const accounts = await ethers.getSigners();
    [deployer, multisig] = accounts;

    // Deploy the xAUDIO logic contract
    const xAUDIO = await ethers.getContractFactory('xAUDIO');
    const xAUDIOInstance = await xAUDIO.deploy();

    // Deploy the xAUDIO proxy
    const xAUDIOProxy = await ethers.getContractFactory('xAUDIOProxy');
    const xAUDIOProxyInstance = await xAUDIOProxy.deploy(xAUDIOInstance.address, multisig.address);
    const xAudioProxied = await ethers.getContractAt('xAUDIO', xAUDIOProxyInstance.address);

    // Initialize the xAUDIO contract
    await xAudioProxied.initialize(
        'xAUDIO',
        'AUDIOWrapper',
        ADDRESSES.audioClaimsManager,
        ADDRESSES.audioDelegateManager,
        ADDRESSES.audioToken,
        100,
        500
    );

    // Set up the accounts
    await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: ['0x4CdF78724f6f80670BeBcd03A69faB9A6778556c']
    });

    user = await ethers.provider.getSigner('0x4CdF78724f6f80670BeBcd03A69faB9A6778556c');

    // Approve audio tokens
    audioToken = new ethers.Contract(ADDRESSES.audioToken, AUDIO_TOKEN_ABI, user);
    await audioToken.approve(xAudioProxied.address, ethers.utils.parseUnits('500'));

    // Mint xAUDIO tokens
    xAudioProxiedUser = await xAudioProxied.connect(user);
    const audioTokensBefore = await audioToken.balanceOf(user.getAddress());
    console.log('User AUDIO token amount before minting:', ethers.utils.formatUnits(audioTokensBefore.toString()));
    await xAudioProxiedUser.mintWithToken(ethers.utils.parseUnits('500'));
    const audioTokensAfter = await audioToken.balanceOf(user.getAddress());
    console.log('User AUDIO token amount after minting:', ethers.utils.formatUnits(audioTokensAfter.toString()));
    const xAudioAmountUser = await xAudioProxied.balanceOf(user.getAddress());
    console.log('User xAUDIO token amount after minting:', ethers.utils.formatUnits(xAudioAmountUser.toString()));
    audioWithdrawableFees = await xAudioProxied.getWithdrawableFees();
    console.log('AUDIO fee amount that is withdrawable:', ethers.utils.formatUnits(audioWithdrawableFees.toString()));

    // Stake AUDIO tokens
    await xAudioProxied.stake(ADDRESSES.serviceProviderEndlineNetwork, ethers.utils.parseUnits('100'));

    // Check stake percentage
    stakePercentage = await xAudioProxied.getCurrentStakedPercentage();
    console.log('Staked percentage:', stakePercentage.toString());

    // Check staked amount before rewards claim
    const stakedAmountBeforeClaim = await xAudioProxied.getTotalStakedAmount();
    console.log('Staked amount before rewards claim:', ethers.utils.formatUnits(stakedAmountBeforeClaim.toString()));

    // Make the rewards claim
    await mineBlocks(50000); // Mine these blocks to ensure previous round has ended
    await xAudioProxied.claimRewards(ADDRESSES.serviceProviderEndlineNetwork);

    // Check staked amount after rewards claim
    const stakedAmountAfterClaim = await xAudioProxied.getTotalStakedAmount();
    console.log('Staked amount after rewards claim:', ethers.utils.formatUnits(stakedAmountAfterClaim.toString()));
    const stakedAmountWithEndline = await xAudioProxied.getStakedAmount(ADDRESSES.serviceProviderEndlineNetwork);
    console.log(
        'Staked amount with Endline Network service provider:',
        ethers.utils.formatUnits(stakedAmountWithEndline.toString())
    );
    stakedFees = await xAudioProxied.getStakedFees();
    console.log('Staked fee amount:', ethers.utils.formatUnits(stakedFees.toString()));

    // Request unstaking
    await xAudioProxied.cooldown(ADDRESSES.serviceProviderEndlineNetwork, stakedAmountWithEndline);

    // Fast forward through the lockup period
    await mineBlocks(46523);

    // Unstake
    await xAudioProxied.unstake();

    // Check balances at the conclusion of the xAUDIO token flow
    const audioInContract = await audioToken.balanceOf(xAUDIOProxyInstance.address);
    console.log('Amount of AUDIO in contract post unstaking:', ethers.utils.formatUnits(audioInContract.toString()));
    const stakedAmountPostUnstaked = await xAudioProxied.getTotalStakedAmount();
    console.log(
        'Total amount of AUDIO staked post unstaking:',
        ethers.utils.formatUnits(stakedAmountPostUnstaked.toString())
    );
    audioWithdrawableFees = await xAudioProxied.getWithdrawableFees();
    console.log('AUDIO fee amount that is withdrawable:', ethers.utils.formatUnits(audioWithdrawableFees.toString()));
    stakedFees = await xAudioProxied.getStakedFees();
    console.log('Staked fee amount:', ethers.utils.formatUnits(stakedFees.toString()));
}

async function mineBlocks(blockCount) {
    for (let i = 0; i < blockCount; ++i) {
        await hre.ethers.provider.send('evm_mine');
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
