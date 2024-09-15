#[starknet::interface]
trait ICounter<T> {
    fn get_counter(self: @T) -> u32;
    fn increase_counter(ref self: T);
}

#[starknet::contract]
pub mod counter_contract {
    use starknet::ContractAddress;
    use kill_switch::{IKillSwitchDispatcher, IKillSwitchDispatcherTrait};
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[derive(Drop, starknet::Event)]
    struct CounterIncreased {
        #[key]
        value: u32,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterIncreased: CounterIncreased,
        OwnableEvent: OwnableComponent::Event
    }

    #[storage]
    struct Storage {
        counter: u32,
        kill_switch: ContractAddress,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_value: u32, kill_switch: ContractAddress) {
        self.counter.write(initial_value);
        self.kill_switch.write(kill_switch);
    }

    #[abi(embed_v0)]
    impl ICounterImpl of super::ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }

        fn increase_counter(ref self: ContractState) {
            let kill_switch = IKillSwitchDispatcher { contract_address: self.kill_switch.read() };

            assert!(kill_switch.is_active() == false, "Kill Switch is active");

            self.counter.write(self.counter.read() + 1);
            self.emit(Event::CounterIncreased(CounterIncreased { value: self.counter.read() }));
        }
    }
}
