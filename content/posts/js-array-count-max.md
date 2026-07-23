---
title: javascript 配列 同じ要素数カウント、最大出力
description: 'JavaScriptで配列内の要素ごとの出現回数を数え、最も多く出現する回数を求めるコードのメモ'
date: 2023-11-28T00:00:00.000Z
image: ''
tags:
  - IT
  - Javascript
categories:
  - IT
---

 
```typescript
const array = [1, 1, 1, 2, 2, 3];

const map = array.reduce(
  (acc, curr) => acc.set(curr, (acc.get(curr) || 0) + 1),
  new Map()
);

console.log([...map.keys()]); // [1, 2, 3]
console.log([...map.values()]); // [3, 2, 1]
console.log([...map.entries()]); // [[1, 3], [2, 2], [3, 1]]

const arrayCountMax = Math.max(...map.values()) //3
```


### 参考


[https://qiita.com/saka212/items/408bb17dddefc09004c8](https://qiita.com/saka212/items/408bb17dddefc09004c8)


[https://pote-chil.com/blog/count-duplicate-array-item](https://pote-chil.com/blog/count-duplicate-array-item)

