// BOOKSTORE CONTRACT WILL HAVE THE FOLLOWING
// ADD BOOK
// GET BOOK DETAILS
// PURCHASE BOOK

use core::starknet::ContractAddress;

#[derive(Copy, Drop, Serde, starknet::Store)]
struct Book {
    name: felt252,
    ownership: ContractAddress,
    price: u8
}

#[starknet::interface]
pub trait IBookStore<TContractState> {
    fn add_book(ref self: TContractState, book_id: felt252, name: felt252, price: u8);
    fn get_book_details(self: @TContractState, book_id: felt252) -> Book;
    fn purchase_book(ref self: TContractState, book_id: felt252, buyer_address: ContractAddress, payment_price: u8);
}

#[starknet::contract]
pub mod BookStore {
    use super::{Book, IBookStore};
    use core::starknet::{
        get_caller_address, ContractAddress,
        storage::{Map, StorageMapReadAccess, StorageMapWriteAccess}
    };

    #[storage]
    struct Storage {
        books: Map<felt252, Book>, // map bookid to books struct
        store_keeper_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BookAdded: BookAdded,
        BookPurchased: BookPurchased
    }

    #[derive(Drop, starknet::Event)]
    struct BookAdded {
        name: felt252,
        book_id: felt252,
        price: u8
    }

    #[derive(Drop, starknet::Event)]
    struct BookPurchased {
        name: felt252,
        book_id: felt252,
        price: u8,
        ownership: ContractAddress
    }

    #[constructor]
    fn constructor(ref self: ContractState, store_keeper_address: ContractAddress) {
      self.store_keeper_address.write(store_keeper_address);
    }

    #[abi(embed_v0)]
    impl BookStoreImpl of IBookStore<ContractState> {
        fn add_book(ref self: ContractState, book_id: felt252, name: felt252, price: u8) {
            let store_keeper_address = self.store_keeper_address.read();

            assert(get_caller_address() == store_keeper_address, 'Only store keeper can add books');

            let book = Book {name: name, price: price, ownership: store_keeper_address};

            self.books.write(book_id, book);

            self.emit(BookPurchased { name, book_id, price, ownership: store_keeper_address })
        }

        fn purchase_book(ref self: ContractState, book_id: felt252, buyer_address: ContractAddress, payment_price: u8) {
            let mut book = self.books.read(book_id);
            
            assert(payment_price < book.price, 'insufficient amount');

            book.ownership = buyer_address;
            self.books.write(book_id, book);

            self.emit(BookPurchased { name: book.name, book_id, price: book.price, ownership: buyer_address});
        }

        fn get_book_details(self: @ContractState, book_id: felt252) -> Book {
            self.books.read(book_id)
        }
    }
}