use superposition_libaccounts::SolveV2Args;

#[test]
fn solve_v2_signed_args_bind_permit_owner() {
    let args = SolveV2Args {
        args: Vec::new(),
        permit_owner: [1; 20],
        transfer_owner: [2; 20],
    };
    let mut changed = args.clone();
    changed.permit_owner = [3; 20];

    assert_ne!(
        borsh::to_vec(&args).unwrap(),
        borsh::to_vec(&changed).unwrap()
    );
}

#[test]
fn solve_v2_signed_args_bind_transfer_owner() {
    let args = SolveV2Args {
        args: Vec::new(),
        permit_owner: [1; 20],
        transfer_owner: [2; 20],
    };
    let mut changed = args.clone();
    changed.transfer_owner = [3; 20];

    assert_ne!(
        borsh::to_vec(&args).unwrap(),
        borsh::to_vec(&changed).unwrap()
    );
}
