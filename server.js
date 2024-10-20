import express from 'express';
import OpenAI from "openai";
import { getPool, getPools } from './pools.js';


const app = express();

const port = 3001;



app.get('/',( req, res) => {
  getPools().then(response => {
        res.send(response.data);
    }).catch(error => {
      console.log("error: ", error);
    })
});


app.get('/pool/:id', (req, res) => {
    getPool(req.params.id).then(response => {
      const records = response.data;
  
      const last20Records = records.slice(-20);

      let APYs = []

      for (let i = 0; i < last20Records.length; i++) {
        APYs.push(last20Records[i]["apy"]);
      }
  
      res.send(APYs);
    }).catch(error => {
      console.log("error: ", error);
      res.status(500).send("An error occurred");
    });
  });




  


app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});

