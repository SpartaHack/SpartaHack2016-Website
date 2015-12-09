$(document).ready( function () {
  
    var table = $('#my-final-table').DataTable({
        scrollY: "800px",
        scrollX:"100%",
        paging: false,
        select: true,
        "oLanguage": { "sSearch": "" }
    });
	
	new $.fn.dataTable.FixedColumns( table, {
        leftColumns: 2
    } );

    $('input').attr('placeholder', "Search")
 
} );