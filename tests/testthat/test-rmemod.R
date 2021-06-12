context('rmemod')

test_that('rmemod catches bad inputs before running algorithm', {
  set.seed(1)
  m1 <- matrix(rbinom(1000 * 50, 1, 0.1), 100)
  
  expect_error(rmemod(m1 + 1), regexp = '0:1')
  
  expect_error(rmemod(m1, bgrate = 1), regexp = 'bgrate')
  expect_error(rmemod(m1, bgrate = 1.5), regexp = 'bgrate')
  expect_error(rmemod(m1, bgrate = -0.1), regexp = 'bgrate')
  
  expect_error(rmemod(m1, minfreq = 1), regexp = 'minfreq')
  expect_error(rmemod(m1, minfreq = 1.5), regexp = 'minfreq')
  expect_error(rmemod(m1, minfreq = -0.1), regexp = 'minfreq')
  
  expect_warning(rmemod(m1, modsize = 10, timeout = 1), 'complexity') 
  expect_error(rmemod(m1, modsize = 1), 'modsize')
  
  expect_error(rmemod(m1, ngenes = 10), regexp = 'ngenes')
  
  expect_message(rmemod(m1, timeout = 1), 'timed out')
  expect_error(rmemod(m1, timeout = -1), 'timeout')
  
  expect_error(rmemod(m1, winnow = 2), 'winnow')
})
