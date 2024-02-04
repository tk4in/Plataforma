/****************************************************************************************************/
/* Root     																						*/
/****************************************************************************************************/
const express = require("express");
const router = express.Router();

const { GetDate, GetUSID, GetNONCE } = require("../utils/utils.js");

router.get("/", (req, res, next) => {


    
});

module.exports = router;