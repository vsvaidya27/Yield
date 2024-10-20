import express from 'express';
import { getBestPool } from "./gpt.js"

const app = express();

const port = 3001;

const POOL_TO_ADDRESS_MAP = {
    "compound_base": "0xf25212e676d1f7f89cd72ffee66158f541246445",
    "compound_arbitrum": "0x9c4ec768c28520b50860ea7a15bd7213a9ff58bf",
    "aave-ethereum": "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2",
    "aave-polygon": "0x794a61358d6845594f94dc1db02a252b5b4814ad",
    "aave-arbitrum": "0x794a61358d6845594f94dc1db02a252b5b4814ad"
}


app.get('/',( req, res) => {
    getBestPool().then(response => {
        let response_obj = {}
        response_obj[response] = POOL_TO_ADDRESS_MAP[response]
        res.send(response_obj);
    }).catch(error => {
      console.log("error: ", error);
    })
});


  


app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});

