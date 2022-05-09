import { someObj } from "@sachets/ui";

console.log(someObj);
const entries = Object.entries(someObj);
for (let index = 0; index < entries.length; index++) {
  const [key, value] = entries[index];
  console.log("key %s has value %s", key, value);
}

// LSP should highlight error about non-existing property
console.log(
  'object from another workspace doesn\'t have key "f". Proof:',
  someObj.f
);
