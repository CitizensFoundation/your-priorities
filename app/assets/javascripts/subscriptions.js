function handlePaymillResponse(error, result) {
    if (error) {
        //alert("ERROR");
        $('#paymill_error').text(processErrorCodes(error.apierror));
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
      exp_year: $('#card_year').val(),
      cardholder: $('#cardholder').val(),
      amount_int: Math.round(parseFloat($('#subscription_amount').val()) * 100),
      currency: $('#subscription_currency').val()

    };
    //alert("Before token: ");
    //alert(card['amount_int']);
    //alert(card['currency']);

    return paymill.createToken(card, handlePaymillResponse);
}

function processErrorCodes(error_code) {
    error_response = 'Unkown error with card payment';
    switch (error_code) {
        case 'field_invalid_card_number':
            error_response="Invalid card number";
            break;
        case 'field_invalid_card_exp_year':
            error_response="Invalid expiry year";
            break;
        case 'field_invalid_card_exp_month':
            error_response="Invalid expiry month";
            break;
        case 'field_invalid_card_exp':
            error_response="Invalid expiry";
            break;
        case 'field_invalid_card_cvc':
            error_response="Invalid CVC code";
            break;
        case 'field_invalid_card_holder':
            error_response="Invalid cardholder";
            break;
        case '3ds_cancelled':
            error_response="3ds cancelled by user";
            break;

    }
    return error_response;
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


