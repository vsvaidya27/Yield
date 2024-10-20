import express from 'express';
import { getBestPool } from "./gpt.js"
import { getAllPoolsInterestRates } from "./pools.js"

const app = express();

const port = process.env.PORT || 3001;

// const POOL_TO_ADDRESS_MAP = {
//     "compound_base": "0xf25212e676d1f7f89cd72ffee66158f541246445",
//     "compound_arbitrum": "0x9c4ec768c28520b50860ea7a15bd7213a9ff58bf",
//     "aave-ethereum": "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2",
//     "aave-polygon": "0x794a61358d6845594f94dc1db02a252b5b4814ad",
//     "aave-arbitrum": "0x794a61358d6845594f94dc1db02a252b5b4814ad"
// }

app.get('/', (req, res) => {
    getBestPool().then(pool_str => {

        let pool_info = pool_str.split(' ');
        let pool = pool_info[0];
        let predicted_pool_apy = parseFloat(pool_info[1]);

        async function getMostRecentapyOfBestPool() {
            let pools_apys = await getAllPoolsInterestRates();
            let apys_of_best_pool = pools_apys[pool];
            let most_recent_apy_of_best_pool = apys_of_best_pool[apys_of_best_pool.length - 1];
            return { pools_apys, most_recent_apy_of_best_pool }; 
        }

        let response_obj = {};

        getMostRecentapyOfBestPool().then(({ pools_apys, most_recent_apy_of_best_pool }) => { 

            let other_pools = {};
            for (let pool_name in pools_apys) {  
                if (pool_name !== pool) {
                    other_pools[pool_name] = pools_apys[pool_name][pools_apys[pool_name].length - 1];
                }
            }

            response_obj["best_pool"] = { [pool]: {"most recent interest rate": most_recent_apy_of_best_pool, "predicted interest rate": predicted_pool_apy} };
            response_obj["other_pools"] = other_pools;
            res.send(response_obj);
        }).catch(error => {
            console.log("error: ", error);
        })
    }).catch(error => {
        console.log("error: ", error);
    })
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
