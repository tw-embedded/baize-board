extern crate proc_macro;

use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, ItemStruct};

#[proc_macro_attribute]
pub fn feature_definition(_attr: TokenStream, item: TokenStream) -> TokenStream {
    let input = parse_macro_input!(item as ItemStruct);
    let struct_name = &input.ident;

    let struct_name_str = struct_name.to_string();
    let variable_name_str = format!("_GLOBAL_{}", struct_name_str.to_uppercase());
    let variable_ident = syn::Ident::new(&variable_name_str, struct_name.span());
    let func_name_str = format!("_INIT_{}", struct_name_str.to_uppercase());
    let func_ident = syn::Ident::new(&func_name_str, struct_name.span());

    let expanded = quote! {
        struct #struct_name;
        static #variable_ident: #struct_name = #struct_name{};
        fn _init_feature_() {
            println!("tm: init feature for struct {}!", stringify!(#struct_name));
            // TODO: add to golbal features
            use init::Feature; // method not found if not use!
            #variable_ident.init();
        }
        #[link_section = ".rust_init"]
        #[no_mangle]
        static #func_ident: fn() = _init_feature_;
    };

    TokenStream::from(expanded)
}

