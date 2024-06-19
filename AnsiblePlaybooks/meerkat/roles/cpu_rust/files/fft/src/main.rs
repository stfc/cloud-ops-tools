// Computes a forward FFT of size nx x ny (4096 x 4096)
use ndarray::{Array2};
use ndrustfft::{ndfft_r2c, Complex, R2cFftHandler, ndfft_r2c_par};
use rand::Rng;
use std::time::Instant;

fn setup_data(nx: usize, ny: usize, n: usize) -> Vec<Array2::<f64>> {
    // set up random data of size (nx x ny x n)
    let mut rng = rand::thread_rng();

    let mut data = vec![Array2::<f64>::zeros((nx, ny)); n];
    for i in 0..data.len(){
        for v in data[i].iter_mut() {
            *v = rng.gen::<f64>();
        }
    }
    return data
}

fn single_core(data: Vec<Array2::<f64>>, mut results: Vec<Array2::<Complex<f64>>>, mut fft_handler: Vec<R2cFftHandler::<f64>>) {
    // calculates forward fourier transform of input data (single core)
    for i in 0..data.len() {
        ndfft_r2c(
            &data[i].view(),
            &mut results[i].view_mut(),
            &mut fft_handler[i],
            0,
        );
    }
}

fn multi_core(data: Vec<Array2::<f64>>, mut results: Vec<Array2::<Complex<f64>>>, mut fft_handler: Vec<R2cFftHandler::<f64>>) {
    // calculates forward fourier transform of input data (multi core)
    for i in 0..data.len() {
        ndfft_r2c_par(
            &data[i].view(),
            &mut results[i].view_mut(),
            &mut fft_handler[i],
            0,
        );
    }
} 

fn main() {
    // set up data size
    let n = 10; // number of arrays to generate
    let (nx, ny) = (4096, 4096); // size of arrays to create

    ////////////////////////////////////////////////////////////////////////////
    // single core 
    ////////////////////////////////////////////////////////////////////////////

    // set up data 
    let data = setup_data(nx, ny, n);
    let results = vec![Array2::<Complex<f64>>::zeros((nx / 2 + 1, ny)); n];
    let fft_handler = vec![R2cFftHandler::<f64>::new(nx); n];

    // run benchmark
    let start = Instant::now();
    single_core(data, results, fft_handler);
    let time = start.elapsed().as_millis() as f64;
    println!("time taken: {:?}", time / 1000.0);

    ////////////////////////////////////////////////////////////////////////////
    // multicore
    ////////////////////////////////////////////////////////////////////////////

    // set up data 
    let data = setup_data(nx, ny, n);
    let results = vec![Array2::<Complex<f64>>::zeros((nx / 2 + 1, ny)); n];
    let fft_handler = vec![R2cFftHandler::<f64>::new(nx); n];

    // run benchmarks
    let start = Instant::now();
    multi_core(data, results, fft_handler);
    let time = start.elapsed().as_millis() as f64;
    println!("time taken: {:?}", time / 1000.0);
}

