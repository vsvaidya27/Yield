export const POOL_TO_ID_MAP = {
    "compound_base": "ae703e6a-c47e-44bb-bb5d-ba65be18aa7e",
    "compound_arbitrum": "8db29638-56de-488a-8b4a-991759ba1544",
    "aave-ethereum": "aa70268e-4b52-42bf-a116-608b370f9501",
    "aave-polygon": "37b04faa-95bb-4ccb-9c4e-c70fa167342b",
    "aave-arbitrum": "d9fa8e14-0447-4207-9ae8-7810199dfa1f"
};

export async function getPoolInterestRates(pool_id) {

    async function getPool(pool_id) {
        const response = await fetch(`https://yields.llama.fi/chart/${pool_id}`);
        return response.json();
      }

    try {
        const response = await getPool(pool_id);
        const records = response.data;
        const last20Records = records.slice(-20);
  
        let APYs = [];
        for (let i = 0; i < last20Records.length; i++) {
          APYs.push(last20Records[i]["apy"]);
        }
  
        return APYs;
    } catch (err) {
        console.log("error: ", err);
        return null; 
    }
}

export async function getAllPoolsInterestRates() {
    let pool_interest_rates_map = {}

    for (const pool in POOL_TO_ID_MAP) {
        pool_interest_rates_map[pool] = await getPoolInterestRates(POOL_TO_ID_MAP[pool]);
    }

    return pool_interest_rates_map;
}


async function getPools() {
    const response = await fetch('https://yields.llama.fi/pools');
    return response.json();

}