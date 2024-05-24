# Checking Dependent Types with Normalization by Evaluation (Swift Version)

I'm translating David Christiansen's 
[bidirectional typechecking Haskell example](https://davidchristiansen.dk/tutorials/implementing-types-hs.pdf) 
into Swift. Why would I do such a thing? It's not because Swift is especially
well-suited to this task! I want to learn about type checking in dependently 
typed languages, and I want to learn more about Swift, so, well, why not?

This project is an incomplete work in progress.

David [said](https://davidchristiansen.dk/tutorials/)
> Please feel free to use or adapt [the examples] for your own purposes. 

But he didn't specify a particular license. So I'm posting this version under 
the MIT license.

## Running the code

Install dependencies (you only need to do this once). You will need
[swift-format](https://github.com/apple/swift-format). I installed this via
Homebrew, as follows, but any method of installation should work so long as it
ends up on your `PATH`

```bash
$ brew install swift-format
```

Run the tests:

```bash
$ make test
```

...and, that's it! There is no executable for now, it's just library code.