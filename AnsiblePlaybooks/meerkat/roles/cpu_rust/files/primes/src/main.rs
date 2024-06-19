use std::time::Instant;
use rayon::iter::{IntoParallelIterator, ParallelIterator};

fn is_prime(n: u32) -> bool {
    // Calculates if n is prime
    (2..=n / 2).all(|i| n % i != 0)
}

fn single_core(max: u32) -> usize {
    // Single core function for calculating primes from 2 to max
    let primes: Vec<u32> = (2..max).filter(|n| is_prime(*n)).collect();
    primes.len()
}

fn multi_core(max: u32) -> usize {
    // Multicore function for calculating primes from 2 to max
    let primes: Vec<u32> = (2..max)
    .into_par_iter()
    .filter(|n| is_prime(*n))
    .collect();
    primes.len()
}

fn main() {
    let max = 1_000_000; // calculate primes up to max value
    // Single core performance
    let start = Instant::now();
    let primes = single_core(max); // calculate primes - single core
    let time = start.elapsed().as_millis() as f64;
    println!("Found {} primes", primes);
    println!("Single core time taken: {:.2?}", time / 1000.0);

    // multicore performance
    let start = Instant::now();
    let primes = multi_core(max); // calculate primes - multicore
    let time = start.elapsed().as_millis() as f64;
    println!("Found {} primes", primes);
    println!("multi core time taken: {:.2?}", time / 1000.0);
}

