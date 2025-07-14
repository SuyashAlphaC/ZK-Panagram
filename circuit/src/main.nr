fn main(guess_hash: Field, answer_hash: pub Field, user: pub Field) {
    let address_pow = user.pow_32(2);
    assert(address_pow == user.pow_32(2));
    assert(guess_hash == answer_hash);
}
