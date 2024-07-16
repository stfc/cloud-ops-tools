// Computes a forward FFT of size nx x ny (4096 x 4096)
use ndarray::{Array2};
use ndrustfft::{ndfft_r2c, Complex, R2cFftHandler, ndfft_r2c_par};
use rand::Rng;
use std::time::Instant;
use num_cpus;

struct BenchmarkValues {
    data: Vec<Array2::<f64>>,
    results: Vec<Array2::<Complex<f64>>>,
    fft_handler: Vec<R2cFftHandler::<f64>>,
    iterations: f64,
    time_in_secs: f64,
    time_taken: f64,
    start: Instant,
}
impl BenchmarkValues {
    fn setup_data(&mut self) {
        // setup data array with random data
        let mut rng = rand::thread_rng();
        for i in 0..self.data.len(){
            for v in self.data[i].iter_mut() {
                *v = rng.gen::<f64>();
            }
        }
    }
    
    fn single_core(&mut self) {
        // Single core fft of data for a given length of time
        self.start = Instant::now();
        while self.time_taken < (self.time_in_secs * 1000.0)  {
            for i in 0..self.data.len() {
                ndfft_r2c(
                    &self.data[i].view(),
                    &mut self.results[i].view_mut(),
                    &mut self.fft_handler[i],
                    0,
                );
            }
            self.time_taken = self.start.elapsed().as_millis() as f64;
            self.iterations += 1.0;
        }
    }

    fn multi_core(&mut self) {
        // Multicore fft of data for a given length of time
        self.start = Instant::now();
        while self.time_taken < (self.time_in_secs * 1000.0)  {
            for i in 0..self.data.len() {
                ndfft_r2c_par(
                    &self.data[i].view(),
                    &mut self.results[i].view_mut(),
                    &mut self.fft_handler[i],
                    0,
                );
            }
            self.time_taken = self.start.elapsed().as_millis() as f64;
            self.iterations += 1.0;
        }
    }

    fn print_results(&self) {
        // Print benchmakr results
        println!("--------------------------");
        println!("Time taken: {}", self.time_taken / 1000.0);
        println!("Completed iterations: {}", self.iterations);
        println!("Iterations per second: {:.3}", self.iterations / (self.time_taken / 1000.0));
        println!("Number of cores {}", num_cpus::get());
    }
}


fn main() {
    // data array dimensions
    let nx = 1024;
    let ny = 1024;
    let nz = 10;

    // Single core parameters
    let mut single_core_values = BenchmarkValues {
        data: vec![Array2::<f64>::zeros((nx, ny)); nz],
        results: vec![Array2::<Complex<f64>>::zeros((nx / 2 + 1, ny)); nz],
        fft_handler: vec![R2cFftHandler::<f64>::new(nx); nz],
        iterations: 0.0,
        time_in_secs: 180.0,
        time_taken: 0.0,
        start: Instant::now(),
    };

    // Multicore parameters
    let mut multi_core_values = BenchmarkValues {
        data: vec![Array2::<f64>::zeros((nx, ny)); nz],
        results: vec![Array2::<Complex<f64>>::zeros((nx / 2 + 1, ny)); nz],
        fft_handler: vec![R2cFftHandler::<f64>::new(nx); nz],
        iterations: 0.0,
        time_in_secs: single_core_values.time_in_secs,
        time_taken: 0.0,
        start: Instant::now(),
    };

    // Single core benchmark
    single_core_values.setup_data();
    single_core_values.single_core();
    single_core_values.print_results();

    // Multicore benchmark
    multi_core_values.setup_data();
    multi_core_values.multi_core();
    multi_core_values.print_results();
}
