import OpenAI from 'openai'
import { getAllPoolsInterestRates } from './pools.js';

const openai = new OpenAI({
  baseURL: 'https://api.red-pill.ai/v1',
  apiKey: 'sk-ORGK92qe5EQDFZmWMVnsRLZUg5BHG4Zt1vzlJ68M5ePgE8B7',
})


export async function getBestPool() {
    const POOL_INTEREST_RATES_MAP = await getAllPoolsInterestRates();
    const stringified_APYs = JSON.stringify(POOL_INTEREST_RATES_MAP); 
    const completion = await openai.chat.completions.create({
      messages: [{ role: 'system', content: "You are an expert in Decentralized Finance and a statistical computer for investment returns. Your goal is to find the highest interest rate pool for my money. You must return me only one word, which is the name of the pool, and only one number, which is your estimated APY for this pool during the next 3 months. I will give you a map from each pool name to the last 20 daily APYs of the pool."}, 
          {role: "user", content: `${stringified_APYs}`} 
      ],
      model: 'gpt-4o',
    })
        return completion.choices[0].message.content;
}
