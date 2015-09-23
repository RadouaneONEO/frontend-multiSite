define([], function () {
    return{
        urls: {
            "deleteDiscount" : "/cart/ajax/removediscount",
            "addDiscount" : "/cart/ajax/applydiscount",
            "changeShipping" : "/cart/ajax/selectshippingtype/",
            "changeCustomerReference" : "/cart/ajax/setreforder",
            "deleteJob" :    "/cart/ajax/removeitem/",
            "deleteJobDesign" :    "/cart/ajax/removedesign/",
            "deleteFileCheck" :    "/cart/ajax/removefilecheck/",
            "setRefJob" :    "/cart/ajax/setrefjob",
            "setMailDeisigner" :    "/cart/ajax/setemaildesigner"
        },
        call : function(action, data, method, params){
            myCart.disable = true;
            if (!method) {method = "POST"}
            if (!params) {params = ""}
            var config = require("config");
            return $.ajax({
                type: method,
                url: "/" + config.prefix + this.urls[action] + params,
                data : data
            }).done(function(resultData) {
                myCart.disable = false;
            }).error(function(){
                myCart.disable = false;
            });
        }

    }
});
