$(document).ready( function () {
  
    var table = $('#my-final-table').DataTable({
        scrollY: "800px",
        scrollX:"100%",
        paging: false,
        select: true
    });
	
	new $.fn.dataTable.FixedColumns( table, {
        leftColumns: 2
    } );
 
} );