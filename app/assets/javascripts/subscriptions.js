function handlePaymillResponse(error, result) {
    if (error) {
        //alert("ERROR");
        $('#paymill_error').text(error.apierror);
        return $('input[type=submit]').attr('disabled', false);
        //alert("AFTER ERROR");
    } else {
        //alert("NOT ERROR " + result.token);
        $('#subscription_paymill_card_token').val(result.token);
        //alert("AFTER NOT ERROR");
        return $('#new_subscription')[0].submit();
    };
}

function processCard() {
  var card;
    card = {
      number: $('#card_number').val(),
      cvc: $('#card_code').val(),
      exp_month: $('#card_month').val(),
      exp_year: $('#card_year').val()
    };
    //alert("Before token: ");
    return paymill.createToken(card, handlePaymillResponse);
}

jQuery(document).ready(function() {
    $('#submit_button').click(function() {
        $('input[type=submit]').attr('disabled', true);
        if ($('#card_number').length) {
            //alert("Before process card");
            processCard();
            return false;
        } else {
            return true;
        }
    });
});
