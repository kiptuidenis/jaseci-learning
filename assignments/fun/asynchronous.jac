async def foo() {
    return print("42");
}

with entry {
    foo();  # ❌ just returns a coroutine object, doesn’t execute it
    foo_run = await foo();  # ✅ works, but only inside another async function
    
}
