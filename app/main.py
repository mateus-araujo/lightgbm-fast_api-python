# Data Handling
import pickle
import numpy as np
from pydantic import BaseModel

# Server
import uvicorn
from fastapi import FastAPI, HTTPException
import logging

# Modeling
import lightgbm

app = FastAPI()

# Initialize logging
logger = logging.getLogger()
# logger.setLevel(logging.DEBUG)
logging.basicConfig(level=logging.DEBUG, filename='sample.log')

clf = pickle.load(open('./data/model.pickle', 'rb'))
enc = pickle.load(open('./data/encoder.pickle', 'rb'))
features = pickle.load(open('./data/features.pickle', 'rb'))


class Data(BaseModel):
    satisfaction_level: float
    last_evaluation: float
    number_project: float
    average_montly_hours: float
    time_spend_company: float
    Work_accident: float
    promotion_last_5years: float
    sales: str
    salary: str


@app.get("/")
def home():
    return "Predicting turnover"


@app.post("/predict")
def predict(data: Data):
    try:
        # Extract data in correct order
        data_dict = data.dict()
        to_predict = [data_dict[feature] for feature in features]

        # Apply one-hot encoding
        encoded_features = list(enc.transform(
            np.array(to_predict[-2:]).reshape(1, -1))[0])
        to_predict = np.array(to_predict[:-2] + encoded_features)

        prediction = clf.predict(to_predict.reshape(1, -1))

        return {
            "data": {
                "prediction": {
                    "left": int(prediction[0])
                }
            }
        }

    except:
        logger.error("Something went wrong!")
        raise HTTPException(status_code=422, detail={"prediction": "error"})
