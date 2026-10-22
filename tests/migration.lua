local root='ts_nlplates_migrate/'
local callback, queries, transactions, mode, checks, plan, logs
local originalPrint=print
local function boot(case)
 mode=case;queries=0;transactions=0;checks=0;plan=nil;logs={};callback=nil
 dofile(root..'config.lua')
 if case=='badconfig' then Config.BlockedResources={} end
 function RegisterCommand(name,fn) assert(name==Config.Command);callback=fn end
 function GetPlayers()
  checks=checks+1
  return (mode=='players' or (mode=='lateplayer' and checks>1)) and {'1'} or {}
 end
 function GetResourceState()
  return mode=='stopping' and 'stopping' or (mode=='lateresource' and checks>1) and 'started' or 'stopped'
 end
 print=function(msg)logs[#logs+1]=msg end
 MySQL={query={await=function(sql)
  queries=queries+1
  if sql:find('information_schema',1,true) then
   return {{tbl='owned_vehicles',col='plate',kind='varchar',engine=mode=='myisam' and 'MyISAM' or 'InnoDB'},
    {tbl='owned_vehicles',col='vehicle',kind='longtext',engine='InnoDB'},
    {tbl='ox_inventory',col='name',kind='varchar',engine='InnoDB'}}
  end
  return mode=='empty' and {} or {{plate=mode=='noncanonical' and 'a-123-bc' or 'A-123-BC'}}
 end},scalar={await=function(sql,values)
  if sql:find('JSON_VALID',1,true) then return mode=='invalidjson' and 1 or 0 end
  if values[1]=='A 123 BC' then return mode=='collision' and 1 or 0 end
  if values[1]=='gloveA 123 BC' or values[1]=='trunkA 123 BC' then return 0 end
  return 1
 end},transaction={await=function(p)
  transactions=transactions+1;plan=p
  return mode~='transactionfail'
 end}}
 dofile(root..'server.lua')
end
boot('normal');callback(12,{'uitvoeren'});assert(queries==0 and transactions==0)
boot('normal');callback(0,{'controle'});assert(queries>0 and transactions==0)
boot('normal');callback(0,{'uitvoeren'});assert(transactions==1 and checks==2 and #plan==5)
assert(plan[1].values[1]=='A 123 BC' and plan[1].values[2]=='A-123-BC')
assert(plan[3].query:find('JSON_SET',1,true))
assert(plan[4].values[1]=='gloveA 123 BC')
for _,case in ipairs({'players','stopping','lateplayer','lateresource','collision','invalidjson','myisam','noncanonical','empty'}) do
 boot(case);callback(0,{'uitvoeren'});assert(transactions==0,case)
end
boot('badconfig');assert(callback==nil)
boot('transactionfail');callback(0,{'uitvoeren'});assert(transactions==1 and logs[#logs]:find('AFGEBROKEN'))
mode='normal';callback(0,{'uitvoeren'});assert(transactions==2,'running lock must clear after error')
print=originalPrint
print('PASS: console access, dry run, plan, offline recheck, collisions, invalid JSON, engine, config and transaction failure/retry')
