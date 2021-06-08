rmemod
====

Discovering functional modules by identifying recurrent and mutually exclusive
mutational patterns in tumors.

A method that identifies functional modules without any information other than
patterns of recurrent and mutually exclusive aberrations (RME patterns) that
arise due to positive selection for key cancer phenotypes.

The algorithm efficiently constructs and searches networks of potential
interactions and identifies significant modules (RME modules) by using the
algorithmic significance test.

---

to install:

```r
# install.packages('devtools')
devtools::install_github('raredd/rmemod')
```

## basic usage

```r
set.seed(1)
x <- matrix(rbinom(1000 * 50, 1, 0.1), 100)
r <- rmemod(x)
r
plot(r)
```

# References

Miller CA, SH Settle, EP Sulman, KD Aldape, A Milosavljevic. Discovering
functional modules relevant for cancer progression by identifying patterns of
recurrent and mutually exclusive aberrations in tumor samples.
_BMC Medical Genomics_ 2011, __4__:34.