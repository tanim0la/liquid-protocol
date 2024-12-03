// SPDX-License-Identifier: GNU
pragma solidity ^0.8.20;

import "./interface/IStrategy.sol";

contract Strategy {
    // curator => array of strategies
    mapping(address => ILiquidStrategy.Strategy[]) curatorStrategies;

    // strategyId => stats
    mapping(bytes32 => ILiquidStrategy.StrategyStats) public strategyStats;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EVENTS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Emitted when a strategy is created
     * @param strategyId unique identifier for the strategy
     * @param curator address of the user creating the strategy
     * @param name descriptive, human-readable name for the strategy
     * @param strategyDescription human-readable description for the strategy
     * @param steps array representing the individual steps involved in the strategy
     * @param minDeposit minimum amount of liquidity a user must provide to participate in the strategy
     * @param maxTVL maximum total value of liquidity allowed in the strategy
     * @param performanceFee fee charged on the strategy
     */
    event CreateStrategy(
        bytes32 indexed strategyId,
        address indexed curator,
        string indexed name,
        string strategyDescription,
        ILiquidStrategy.Step[] steps,
        uint256 minDeposit,
        uint256 maxTVL,
        uint256 performanceFee
    );

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       PUBLIC FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Create a strategy
     * @param _name descriptive, human-readable name for the strategy
     * @param _strategyDescription human-readable description for the strategy
     * @param _steps array representing the individual steps involved in the strategy
     * @param _minDeposit minimum amount of liquidity a user must provide to participate in the strategy
     * @param _maxTVL maximum total value of liquidity allowed in the strategy
     * @param _performanceFee fee charged on the strategy
     */
    function createStrategy(
        string memory _name,
        string memory _strategyDescription,
        ILiquidStrategy.Step[] memory _steps,
        uint256 _minDeposit,
        uint256 _maxTVL,
        uint256 _performanceFee
    ) public {
        bytes32 _strategyId = keccak256(abi.encodePacked(msg.sender, _name, _strategyDescription));
        ILiquidStrategy.Strategy memory _strategy = ILiquidStrategy.Strategy({
            strategyId: _strategyId,
            curator: msg.sender,
            name: _name,
            strategyDescription: _strategyDescription,
            steps: _steps,
            minDeposit: _minDeposit,
            maxTVL: _maxTVL,
            performanceFee: _performanceFee
        });

        // Validate curator's strategy steps
        require(_validateSteps(_steps), "Invalid steps");

        // Store curator's strategy
        curatorStrategies[msg.sender].push(_strategy);

        // Initialize strategy stats
        strategyStats[_strategyId] = ILiquidStrategy.StrategyStats({
            totalDeposits: 0,
            totalUsers: 0,
            totalFeeGenerated: 0,
            lastUpdated: block.timestamp
        });

        emit CreateStrategy(
            _strategyId, msg.sender, _name, _strategyDescription, _steps, _minDeposit, _maxTVL, _performanceFee
        );
    }

    /**
     * @dev Get all strategies for a curator
     * @param _curator address of the user that created the strategies
     */
    function getStrategy(address _curator) public view returns (ILiquidStrategy.Strategy[] memory) {
        return curatorStrategies[_curator];
    }
    /**
     * @dev Get data on a particular strategy
     * @param _strategyId ID of a strategy
     */

    function getStrategyStats(bytes32 _strategyId) public view returns (ILiquidStrategy.StrategyStats memory) {
        return strategyStats[_strategyId];
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Validate each step in the strategy
     * @param steps array representing the individual steps involved in the strategy
     */
    function _validateSteps(ILiquidStrategy.Step[] memory steps) internal view returns (bool) {
        for (uint256 i = 0; i < steps.length; i++) {
            // Validate connector address
            require(steps[i].connector != address(0), "Invalid connector address");

            // Validate assets
            for (uint256 j; j < steps[i].assetsIn.length; j++) {
                require(steps[i].assetsIn[j] != address(0), "Invalid input asset");
            }
            if (steps[i].actionType != IConnector.ActionType.SUPPLY) {
                require(steps[i].assetOut != address(0), "Invalid output asset");
            }

            // Validate amount ratio
            require(steps[i].amountRatio > 0 && steps[i].amountRatio <= 10_000, "Invalid amount ratio"); // Max 100%

            // Validate connector supports action
            IConnector connector = IConnector(steps[i].connector);
            require(
                _isValidActionForConnector(connector.getConnectorType(), steps[i].actionType),
                "Invalid action for connector type"
            );
        }

        return true;
    }

    /**
     * @dev Validates if an action is valid for a connector type
     * @param connectorType Type of connector
     * @param actionType Type of action
     */
    function _isValidActionForConnector(IConnector.ConnectorType connectorType, IConnector.ActionType actionType)
        internal
        pure
        returns (bool)
    {
        if (connectorType == IConnector.ConnectorType.LENDING) {
            return actionType == IConnector.ActionType.SUPPLY || actionType == IConnector.ActionType.WITHDRAW
                || actionType == IConnector.ActionType.BORROW || actionType == IConnector.ActionType.REPAY;
        } else if (connectorType == IConnector.ConnectorType.DEX) {
            return actionType == IConnector.ActionType.SWAP;
        } else if (connectorType == IConnector.ConnectorType.YIELD) {
            return actionType == IConnector.ActionType.STAKE || actionType == IConnector.ActionType.UNSTAKE
                || actionType == IConnector.ActionType.CLAIM;
        }

        return false;
    }
}