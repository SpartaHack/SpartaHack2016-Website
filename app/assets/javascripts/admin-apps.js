function createSelects() {

    $('#status-multi').select2({
      minimumResultsForSearch: -1,
    });

    // hide old selection arrow;
    $('b[role="presentation"]').hide();
    $('.select2-selection__arrow').append('<i class="fa fa-angle-down"></i>');  
    $('.select2-container--open').append('<i class="fa fa-angle-up"></i>'); 
}

function confirmJavascript() {
  $.ajax({
    url: "/javascript/confirm",
    context: document.body
  })
}

$(document).ready( function () {
    setTimeout(function(){
        var table = $('#my-final-table').DataTable({
            scrollY: "60vh",
            scrollX:"300px",
            paging: false,
            select: true,
            "oLanguage": { "sSearch": "" },
            fixedColumns:   {
                leftColumns: 4
            }
        });

        $('input[type=search]').attr('placeholder', "Search")

        confirmJavascript();
        setInterval(confirmJavascript, 10000); // invoke each 10 seconds
        createSelects();
    }, 500);
    

    $(".status").change(function() {
        $.ajax({
            url: "/admin/applications/status",
            async: false,
            type: "post",
            context: document.body,
            data: $(this).serialize()
        })
    })

    $("#multi-submit").click(function(e){
        e.preventDefault();

        for (i=$("#start").val(); i<parseInt($("#end").val())+1; i++ ){
            $("#"+i+" form select").val($("#status-multi").val()).trigger("change");
        }
        location.reload();
    })

    setTimeout(function(){$('#popup-wrapper').fadeOut('slow')}, 500)
} );

