# rvalidator

The rvalidator module aims to take away the boilerplate of implementing validating functions,
while being agnostic of the verification rules and error handling practices.

This module is based on the idea that a Record should have its own verification specification.
Since a Record is an aggregates of multiple fields, a Specification for a Record is implemented as a set of constraints per field.

## Status

The current version of the library is 0.1.0 and is subject for breaking changes until it reaches its first stable version.
