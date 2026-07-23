---
title: reactでサイン機能をするためにreact-signature-canvasためしてみた
description: 'Reactで手書きサイン機能を実装できるreact-signature-canvasを試し、実装時にハマった点をまとめた'
date: 2024-11-03T00:00:00.000Z
image: ''
tags:
  - IT
  - Javascript
  - React
  - Next.js
categories:
  - React
---

 
## **react-signature-canvas**


react-signature-canvasは、Reactアプリケーションでサイン機能を簡単に実装できる人気のライブラリ


### 主な特徴:

- キャンバスベースのシンプルなサイン機能
- タッチデバイスとマウスの両方に対応
- サインのクリア、保存、読み込みなどの基本機能を提供
- カスタマイズ可能なスタイルとオプション

### やってみて


公式を見ながらやったら意外といけた


useRefを使うのと保存したデータURLを取り込んだ時に画像が小さくなってしまうとこに少し困った。


```javascript

import SignatureCanvas from "react-signature-canvas";
import { FC, useState, useRef, useEffect } from "react";




/**
 * サイン
 *
 * @returns サイン
 */
const Signature: FC<Props> = () => {


  const [trimmedDataURL, setTrimmedDataURL] = useState<string>("");
  const padRef = useRef<SignatureCanvas>(null);


  /* -------------------------------- Methods ------------------------------- */

  /**
   * サインクリア
   *
   */
  const clear = () => {
    padRef.current?.clear();
  };

  /**
   *サインURlに変換保存
   *
   */
  const trim = () => {
    const url = padRef.current?.getTrimmedCanvas().toDataURL("image/png");
    if (url) {
      setTrimmedDataURL(url);

      // どこかへ保存する
    }
  };

  useEffect(() => {
    /**
     *初期実行
     *
     */
    const init = async () => {

				const url = "ここで保存先から取得"
	      
	      // fromDataURLでSignatureCanvasに
	      // 保存したデータURL取り込むきちんと幅と高さを合わせないと画像が小さくなったりする
        padRef.current?.fromDataURL(url, {
          width: 800,
          height: 200
        });
        setTrimmedDataURL(url);
      }
    };

    init();
  }, []);


  return (
    <>
      <SignatureCanvas
        penColor="white"
        backgroundColor="gray"
        canvasProps={{ width: 800, height: 200 }}
        ref={padRef}
      />
      <div>
        {trimmedDataURL ? (
          <img alt="signature" src={trimmedDataURL} width={80} height={20} />
        ) : null}
      </div>Ï
          <Button onClick={() => clear()} >
            clear
          </Button>
          <Button onClick={() => trim()} >
	           trim
          </Button>

    </>
  );
};




```


参考


[react-signature-canvas - npm](https://www.npmjs.com/package/react-signature-canvas)


[agilgur5/react-signature-canvas: A React wrapper component around signature_pad (in < 150 LoC). Unopinionated and heavily updated fork of react-signature-pad](https://github.com/agilgur5/react-signature-canvas)

