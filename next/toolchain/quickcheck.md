# Property testing in QuickCheck

## Property testing

Property testing is about testing a given property based on random inputs.

For example, the following is a property that holds for `Array`

> For any `n` that is non-negative (and within range of `Int` due to implementation limit):
after `n` insertions, the `length` method should return exactly `n`.

Using normal testing, we may just test several cases for `n`, often neglecting the corner cases. With property testing, however,
random test data are generated, making it possible to generate unexpected input.

## QuickCheck

QuickCheck was originally introduced in paper [QuickCheck: a lightweight tool for random testing of Haskell programs](https://doi.org/10.1145/351240.351266), 
which became [the Haskell library](https://github.com/nick8325/quickcheck) that popularized the property testing. 

MoonBit has introduced QuickCheck and made some modifications to it.

## Using QuickCheck

To use the library, you need to add `moonbitlang/quickcheck` as dependency. We assume you are familiar with the module / package system in MoonBit. Otherwise check out [package manage tour](/toolchain/moon/package-manage-tour.md).

### Implementing `Arbitrary`

The framework needs to know how to generate data for a given type.

To do so, we need to implement the `Arbitrary` trait for our data.

### Writing Tests

We need to define a property and let it execute.

### Shrinking

## Reference

[README of QuickCheck](https://github.com/moonbitlang/quickcheck)