function createSelects() {

    $('#status-multi').select2({
      minimumResultsForSearch: -1,
    });

    // hide old selection arrow;
    $('b[role="presentation"]').hide();
    $('.select2-selection__arrow').append('<i class="fa fa-angle-down"></i>');  
    $('.select2-container--open').append('<i class="fa fa-angle-up"></i>'); 
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

        createSelects();
    }, 500);
    

    $(".status").change(function() {
        $.ajax({
            url: "/admin/users/applications",
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

