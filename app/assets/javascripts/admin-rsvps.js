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
    
    setTimeout(function(){$('#popup-wrapper').fadeOut('slow')}, 500)
} );

