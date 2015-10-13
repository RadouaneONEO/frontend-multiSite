(function ($) {
    $(document).ready(function () {
      if($('#pccustomers-address-billingaddresses-form')[0]){
         if ($('#edit-vatnumber-number').val()) {
                    $('#isUserCompany').attr('disabled', true);
                } else {
                    $('#isUserCompany').attr('disabled', false);
                }
      }

      $('.save-button').click(function (e) {
          $('.messages.error').remove();
          $('#pccustomers-newaddress-form .required').removeClass("error");
          var errorMarkup = "<div class='messages error'><ul>";
          var errorMsgs = new Array();
          $('#pccustomers-newaddress-form .required').each(function(i, elem) {
            var _this = $(this);
            if(_this.val() == "" || (_this.val().length <= 3 && _this.name !="country") ) {
              var inputName = $(elem).attr('name');
              _this.addClass('error');
              errorMsgs[i] = "Le champ "+inputName+" est requis.";
              errorMarkup += "<li>"+errorMsgs[i]+"</li>";
            }
          });  
          errorMarkup += "</ul></div>";
          $( "#content h1:first" ).after( errorMarkup );
          if(errorMsgs.length != 0 ) {
            e.preventDefault();
          }
      });
         
    });
    
  Drupal.behaviors.pccustomers= {
    detach: function (context) {
    },
    attach: function(context, settings) {
    var UserCompany;

    /* display  vat & company input afther click box */
    $("#isUserCompany").live('click', function () {
        if (this.checked){
            UserCompany = "yes";
        } else {
            UserCompany = "no";
        }
    });
    
         $('#pccustomers-newaddress-billingaddresses-form').submit(function (e) {
                           var number = $('.number');
                           var company = $('#companyInput');
                           if (UserCompany == "yes") {
                               if (number.val() == '' || company.val() == '') {
                                   e.preventDefault();
                                    number.addClass('error');
                                    company.addClass('error');

                               }
                           }
           });
        
        
       $('#edit-country').change(function () {
                var url = Drupal.settings.basePath + '?q=js/country/' + $(this).val();
                $.getJSON(url, null, function (data) {
                    $('#edit-vatnumber-country').val(data.vatPrefix).trigger('change');
                });
            });
    }
  }

})(jQuery);

function pccustomers_login_form_submit(form,triggeringElement) {
  var url = form.attr('action');
  var data = form.serialize();

  form.css('cursor', 'wait');

  if (triggeringElement) {
    data = '_triggering_element_name=' + triggeringElement.attr("name") + '&' + data;
  }

  data = data + '&op=ajax';

  jQuery.ajax({
    type: 'POST',
    url: url,
    data: data,
    success: function(data){
      form.html(jQuery('#' + form.attr('id'), data).html());
      Drupal.attachBehaviors(form);
    },
    complete: function (){
      form.css('cursor', 'default');
    }
  });
};


