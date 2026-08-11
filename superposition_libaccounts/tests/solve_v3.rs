use superposition_libaccounts::{Args, Asset, SolveV3Args};

#[test]
fn solve_v3_signed_args_bind_permit_owner() {
    let args = SolveV3Args {
        args: Vec::new(),
        permit_owner: [1; 20],
        transfer_owner: [2; 20],
    };
    let encoded = borsh::to_vec(&args).unwrap();
    let mut changed = args.clone();
    changed.permit_owner = [3; 20];
    assert_ne!(encoded, borsh::to_vec(&changed).unwrap());
}

#[test]
fn solve_v3_signed_args_bind_transfer_owner() {
    let args = SolveV3Args {
        args: Vec::new(),
        permit_owner: [1; 20],
        transfer_owner: [2; 20],
    };
    let encoded = borsh::to_vec(&args).unwrap();
    let mut changed = args.clone();
    changed.transfer_owner = [3; 20];
    assert_ne!(encoded, borsh::to_vec(&changed).unwrap());
}

#[test]
fn solve_v3_assets_are_single_byte_ids() {
    assert_eq!(borsh::to_vec(&Asset::USDC).unwrap(), vec![0]);
    assert_eq!(borsh::to_vec(&Asset::ARB).unwrap(), vec![1]);
    assert_eq!(borsh::to_vec(&Asset::WETH).unwrap(), vec![2]);
}

#[test]
fn solve_v2_dud_and_solve_v3_keep_stable_discriminants() {
    assert_eq!(borsh::to_vec(&Args::SolveV2Dud).unwrap(), vec![4]);
    let args = Args::SolveV3 {
        slot: 0,
        args: SolveV3Args {
            args: Vec::new(),
            permit_owner: [0; 20],
            transfer_owner: [0; 20],
        },
        sig: superposition_libaccounts::Sig([0; 64]),
    };
    assert_eq!(borsh::to_vec(&args).unwrap()[0], 7);
}
