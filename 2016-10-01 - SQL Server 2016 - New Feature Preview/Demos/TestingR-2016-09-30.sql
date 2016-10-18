exec sp_execute_external_script  @language =N'R',    
@script=N'OutputDataSet<-InputDataSet',      
@input_data_1 =N'select 1 as hello'    
with result sets (([hello] int not null));    

sp_configure 'external scripts enabled', 1
reconfigure


seq(from = 0, to = 100, by = .1)

exec sp_execute_external_script  @language =N'R',    
@script=N'OutputDataSet<-seq(from = 0, to = 100, by = .1)',      
@input_data_1 =N'select 1 as hello'    
with result sets (([hello] int not null));    