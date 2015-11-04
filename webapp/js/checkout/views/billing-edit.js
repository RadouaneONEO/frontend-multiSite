define([
    'backbone',
    'text!../templates/billing-edit.html',
    'views/Error',
    './vat-number-popup',
    '../helpers/ajaxCaller'
], function(Backbone, billingEditTemplate, errorView, vatView, ajaxCaller) {

    return Backbone.View.extend({
        template: _.template(billingEditTemplate),
        events: {
            "change #baEditSelect": "changeBA",
            "click #saveEditBA": "saveBA",
            "blur #vatNumberBA" : "showPopUp",
	    "change #vatNumberBA" : "detectChanges",
            "change #countryList" : "changeCountry",
	    "click #isUserCompany" : "enableSaving"
        },
        initialize: function(model) {
	    this.enableSave = true;
            this.config = require("config");
            this.model = model;
            this.render();
	    this.changesVatNumber = false;
            this.model.on("change", this.render, this);
	    this.vatFormats = [
	        {'BE': 10},
		{'NL' : 12},
    		{'LU' : 8},
		{'FR' : 11}
	    ]	
        },
	validateVat : function(){
	    var trgObject = {};
	    var vatNumberBA = $("#vatNumberBA").val().replace(/\./g, "").replace(/ /g,"");
	    trgObject[$('#countryIsoBA').val()] = vatNumberBA.length;
	    var result = _.findWhere(this.vatFormats, trgObject);
	    switch($('#countryIsoBA').val()) {
                case 'BE':
                    decision = (vatNumberBA.charAt(0) == 0) ? true : false;
                break;
                case 'NL':
                case 'LU':
                    decision = ($.isNumeric(vatNumberBA)) ? true : false;
                break
                default:
                    decision = true;
                break;
            }
            if (!result) {
                decision = false;
            }
            
	    return decision;
	},
	enableSaving : function() {
            if (!$("#isUserCompany").is(":checked")) {
                this.enableSave = true;
            }
        },
    render: function() {
        this.setElement(this.template({
            "model": this.model.toJSON()
        }));
        $(this.config.editBox).find(".billingBox").html(this.$el);
        this.displayVatBloc();

        this.$('select').select2();
    },
	detectChanges : function() {
	    this.changesVatNumber = true;
	},
        errors: function (isPaymentButton) {
            if(isPaymentButton)
                return false;
            var me = this;
            var result = null;
            this.$('.baInputs').css('border-color', '');
            this.$("#companyInput").css('border-color', '');
            this.$("#vatNumberBA").css('border-color', '');
            $('.baInputs').each(function (baInputs) {
                if ($(this).val() == '') {
                    $(this).css('border-color', 'red');
                    result = me.config.labels["BaFieldRequired"];
                    return false;
                } else if($(this).val().length <= 2 || ($(this).attr('id') == 'baPostalCode' && $(this).val().length <= 3)) {
		    $(this).css('border-color', 'red');
		    result = me.config.labels["invalidCharactersLength"];
		}
            });
            if (result) {
                return result;
            }
            if (
                $("#isUserCompany").is(":checked") && ($("#companyInput").val() == "" || $("#vatNumberBA").val() == "")
                ) {
                $("#companyInput").css('border-color', 'red');
                $("#vatNumberBA").css('border-color', 'red');
                return this.config.labels["fieldCmpVatNumber"];
            }
        },
        showPopUp: function(e){
	    this.enableSave = false;
            var elmTarget = $(e.currentTarget);
            var me = this;
	    var vatNumberBA = elmTarget.val().replace(/\./g, "").replace(/ /g,"");
	    var resultValidateVat = this.validateVat();
	    elmTarget.css("border-color", "");
            $('#countryIsoBA').css("border-color", "");
	    $('.vatAlreadyUsed').parent().hide();
            if (!resultValidateVat && elmTarget.val().length > 0) {
                elmTarget.css("border-color", "red");
                $('#countryIsoBA').css("border-color", "red");
                elmTarget.val('');
                me.enableSave = false;
                myCheckout.errorView.render(me.config.labels["InvalidVatNumber"]);
                $(window).scrollTop($(me.config.containerId).offset().top);
            } else {
                if (elmTarget.val().length > 0) {
                    ajaxCaller.call("getBillingAccountFromVat",
                        {"vatNumber" : this.$('#countryIsoBA').val()+vatNumberBA},
                    'GET').done(function(result) {
                        if(_.isEmpty(result.data) == false && me.changesVatNumber == true) {
			    $('.vatAlreadyUsed').parent().show();
                        } else {
			    me.enableSave = true;    
			}
                    });
		return false;
                }
	    }
        },
        saveBA: function(e) {
            var me = this;
	    var billingError = this.errors();
            if( billingError) {
                myCheckout.errorView.render(billingError);
                $(window).scrollTop($(this.config.containerId).offset().top);
                return false;
            }
	    if(this.enableSave == false) {
                return false;
            }
	   e.preventDefault();
           return  ajaxCaller.call("saveBillingAccount",
                {
                    "id": this.$('#baEditSelect').val(),
                    "name": this.$('#baName').val(),
                    "street": this.$('#baStreet').val(),
                    "city": this.$('#baCity').val(),
                    "postalCode": this.$('#baPostalCode').val(),
                    "country": this.$('#countryList').val(),
                    "company": this.$('#companyInput').val(),
                    "vatNumber": this.$('#countryIsoBA').val() + this.$('#vatNumberBA').val()
                    
                }, 'POST').done(function(result) {
		    if (result.id != $('#baEditSelect').val() && $('#baEditSelect').val() != 0) {
                        var newBillngAccountList = jQuery.extend(true, {}, me.model.get('billingAccouts'));
		        newBillngAccountList = _.without(newBillngAccountList, _.findWhere(newBillngAccountList, {id: parseInt($('#baEditSelect').val())}));
                        newBillngAccountList[_.toArray(newBillngAccountList).length] = result;
                        me.model.set({'billingAccouts': newBillngAccountList, 'defaultBA': result});
		    } else if($('#baEditSelect').val() == 0) {
			var newBillngAccountList = jQuery.extend(true, {}, me.model.get('billingAccouts'));
                        newBillngAccountList[_.toArray(newBillngAccountList).length] = result;
                        me.model.set({'billingAccouts': newBillngAccountList, 'defaultBA': result});
		    }
                });
        },
        changeBA: function(e) {
            var elmTarget = $(e.currentTarget);
            var data = this.model.toJSON();
            var targetBA = _.find(data.billingAccouts, function(billingAccount) {
                return elmTarget.val() == billingAccount.id
            });
            if (targetBA != undefined) {
                this.$('#baName').val(targetBA.name);
                this.$('#baStreet').val(targetBA.street);
                this.$('#baCity').val(targetBA.city);
                this.$('#baPostalCode').val(targetBA.postalCode);
                this.$('#countryList').val(targetBA.country);
                this.$('#companyInput').val(targetBA.company);
                this.$('#vatNumberBA').val(targetBA.vatNumber);
                this.displayVatBloc();
            } else if (elmTarget.val() == 0) {
                this.$('.baInputs').val("");
                this.$("#companyInput").val("");
                this.$("#vatNumberBA").val("");
            }
        },
        displayVatBloc: function(){
            document.getElementById("isUserCompany").checked = false;
            this.$(".form-item-invoice-address-current-company").hide();
            this.$(".form-item-invoice-address-current-vatNumber").hide();
            if(this.$('#companyInput').val() != "" && this.$('#vatNumberBA').val()!= "") {
                document.getElementById("isUserCompany").checked = true;
                this.$(".form-item-invoice-address-current-company").show();
                this.$(".form-item-invoice-address-current-vatNumber").show();
            }
        },
        changeCountry: function(e){
	    $('#vatNumberBA').val('');
            this.$("#countryIsoBA").val(_.findWhere(this.model.get("countries"), {id : parseInt($(e.currentTarget).val())}).iso);
        }
    });
});
