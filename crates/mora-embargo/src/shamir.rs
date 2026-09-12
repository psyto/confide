//! Shamir secret sharing over GF(256) — k-of-n, byte-wise.
//!
//! Used to split the seal key across release agents so that **no single agent, and no group
//! smaller than k, can open an embargoed disclosure** — and so that opening at T needs nothing
//! from the holder.

const POLY: u16 = 0x11b; // AES field polynomial

fn mul(a: u8, b: u8) -> u8 {
    let (mut a, mut b, mut acc) = (a as u16, b as u16, 0u16);
    while b != 0 {
        if b & 1 != 0 {
            acc ^= a;
        }
        b >>= 1;
        a <<= 1;
        if a & 0x100 != 0 {
            a ^= POLY;
        }
    }
    acc as u8
}

fn pow(mut base: u8, mut exp: u32) -> u8 {
    let mut acc = 1u8;
    while exp > 0 {
        if exp & 1 == 1 {
            acc = mul(acc, base);
        }
        base = mul(base, base);
        exp >>= 1;
    }
    acc
}

/// Multiplicative inverse in GF(256): a^254 (Fermat). `a` must be non-zero.
fn inv(a: u8) -> u8 {
    debug_assert!(a != 0, "GF(256) has no inverse for 0");
    pow(a, 254)
}

/// Evaluate a polynomial (coeffs[0] = constant term) at `x`.
fn eval(coeffs: &[u8], x: u8) -> u8 {
    let mut acc = 0u8;
    for c in coeffs.iter().rev() {
        acc = mul(acc, x) ^ c;
    }
    acc
}

/// Split `secret` into `n` shares, any `k` of which reconstruct it.
///
/// Share x-coordinates are `1..=n` (0 is reserved for the secret itself).
pub fn split(secret: &[u8], k: u8, n: u8, rng: &mut impl FnMut() -> u8) -> Vec<(u8, Vec<u8>)> {
    assert!(k >= 1 && k <= n, "need 1 <= k <= n");
    assert!(n >= 1, "need at least one share");

    let mut shares: Vec<(u8, Vec<u8>)> = (1..=n).map(|x| (x, Vec::with_capacity(secret.len()))).collect();

    for &byte in secret {
        // Random polynomial of degree k-1 with constant term = this secret byte.
        let mut coeffs = Vec::with_capacity(k as usize);
        coeffs.push(byte);
        for _ in 1..k {
            coeffs.push(rng());
        }
        // A degree-(k-1) polynomial needs a non-zero leading coefficient, or k-1 shares suffice.
        if k > 1 {
            let last = coeffs.len() - 1;
            if coeffs[last] == 0 {
                coeffs[last] = 1;
            }
        }
        for (x, out) in shares.iter_mut() {
            out.push(eval(&coeffs, *x));
        }
    }
    shares
}

/// Reconstruct the secret from `k` or more shares by Lagrange interpolation at x = 0.
pub fn combine(shares: &[(u8, Vec<u8>)]) -> Vec<u8> {
    assert!(!shares.is_empty(), "need at least one share");
    let len = shares[0].1.len();
    let mut out = vec![0u8; len];

    for pos in 0..len {
        let mut acc = 0u8;
        for (i, (xi, yi)) in shares.iter().enumerate() {
            // Lagrange basis L_i(0) = prod_{j != i} x_j / (x_j - x_i); in GF(2^n), minus is xor.
            let mut basis = 1u8;
            for (j, (xj, _)) in shares.iter().enumerate() {
                if i == j {
                    continue;
                }
                basis = mul(basis, mul(*xj, inv(*xj ^ *xi)));
            }
            acc ^= mul(yi[pos], basis);
        }
        out[pos] = acc;
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn det_rng() -> impl FnMut() -> u8 {
        let mut s: u8 = 7;
        move || {
            s = s.wrapping_mul(31).wrapping_add(17);
            s
        }
    }

    #[test]
    fn any_k_of_n_reconstructs() {
        let secret = b"a 32-byte seal key for the demo!";
        let mut r = det_rng();
        let shares = split(secret, 3, 5, &mut r);
        for combo in [[0, 1, 2], [0, 2, 4], [1, 3, 4], [2, 3, 4]] {
            let picked: Vec<_> = combo.iter().map(|&i| shares[i].clone()).collect();
            assert_eq!(combine(&picked), secret.to_vec(), "combo {combo:?} failed");
        }
    }

    #[test]
    fn fewer_than_k_does_not_reconstruct() {
        let secret = b"a 32-byte seal key for the demo!";
        let mut r = det_rng();
        let shares = split(secret, 3, 5, &mut r);
        let two = vec![shares[0].clone(), shares[1].clone()];
        assert_ne!(combine(&two), secret.to_vec());
    }

    #[test]
    fn k_equals_n_is_all_or_nothing() {
        let secret = b"key";
        let mut r = det_rng();
        let shares = split(secret, 3, 3, &mut r);
        assert_eq!(combine(&shares), secret.to_vec());
        assert_ne!(combine(&shares[..2]), secret.to_vec());
    }
}
