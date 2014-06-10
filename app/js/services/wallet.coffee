class Wallet

  get_account: (name) ->
      return {
          address: "XTS...test"
      }


  constructor: (@q, @log, @rpc, @interval) ->
    @log.info "---- Wallet Constructor ----"
    @wallet_name = ""
    @info =
      network_connections: 0
      balance: 0
      wallet_open: false
      last_block_num: 0
      last_block_time: null
    @watch_for_updates()


  create: (wallet_name, spending_password) ->
    @rpc.request('wallet_create', [wallet_name, spending_password]).then (response) =>
      #success()

  get_balance: ->
    @rpc.request('wallet_get_balance').then (response) ->
      asset = response.result[0]
      {amount: asset[0], asset_type: asset[1]}

  get_wallet_name: ->
    @rpc.request('wallet_get_name').then (response) =>
      console.log "---- current wallet name: ", response.result
      @wallet_name = response.result

  get_info: ->
    @rpc.request('get_info').then (response) ->
      response.result

  wallet_add_contact_account: (name, address) ->
    @rpc.request('wallet_add_contact_account', [name, address]).then (response) ->
      response.result

  wallet_account_register: (account_name, pay_from_account, public_data, as_delegate) ->
    @rpc.request('wallet_account_register', [account_name, pay_from_account, public_data, as_delegate]).then (response) ->
      response.result

  wallet_rename_account: (current_name, new_name) ->
    @rpc.request('wallet_rename_account', [current_name, new_name]).then (response) ->
      response.result
  
  blockchain_list_delegates: ->
    @rpc.request('blockchain_list_delegates').then (response) ->
      response.result

  open: ->
    @rpc.request('wallet_open', ['default']).then (response) ->
      response.result

  wallet_account_balance: ->
    @rpc.request('wallet_account_balance').then (response) ->
      response.result

  get_block: (block_num)->
    @rpc.request('blockchain_get_block_by_number', [block_num]).then (response) ->
      response.result

  wallet_get_account: (name)->
    @rpc.request('wallet_get_account', [name]).then (response) ->
      response.result

  wallet_remove_contact_account: (name)->
    @rpc.request('wallet_remove_contact_account', [name]).then (response) ->
      response.result

  blockchain_get_config: ->
    @rpc.request('blockchain_get_config').then (response) ->
      response.result

  wallet_set_delegate_trust_level: (delName, trust)->
    @rpc.request('wallet_set_delegate_trust_level', [delName, trust]).then (response) ->
      response.result

  wallet_list_contact_accounts: ->
    @rpc.request('wallet_list_contact_accounts').then (response) ->
      response.result

  execute_command_line: (command)->
    @rpc.request('execute_command_line', [command]).then (response) ->
      response.result=">> " + command + "\n\n" + response.result;
      

  blockchain_list_registered_accounts: ->
    @rpc.request('blockchain_list_registered_accounts').then (response) ->
      reg = []
      console.log response.result
      angular.forEach response.result, (val, key) =>
        reg.push
          name: val.name
          owner_key: val.owner_key
      reg

  watch_for_updates: =>
    @interval (=>
      @get_info().then (data) =>
        #console.log "watch_for_updates get_info:>", data
        if data.blockchain_head_block_num > 0
          @get_block(data.blockchain_head_block_num).then (block) =>
            @info.network_connections = data.network_num_connections
            #@info.balance = data.wallet_balance[0][0]
            @info.wallet_open = data.wallet_open
            @info.wallet_unlocked = data.wallet_unlocked_seconds_remaining > 0
            #@info.last_block_time = @toDate(block.blockchain_head_block_time)
            @info.last_block_time = block.blockchain_head_block_time
            @info.last_block_num = data.blockchain_head_block_num
        else
          @info.wallet_unlocked = data.wallet_unlocked_seconds_remaining > 0
      , =>
        @info.network_connections = 0
        @info.balance = 0
        @info.wallet_open = false
        @info.wallet_unlocked = false
        @info.last_block_time = null
        @info.last_block_num = 0
    ), 2500

  get_transactions: (account)=>
    # TODO: search for all deposit_op_type with asset_id 0 and sum them to get amount
    # TODO: cache transactions
    # TODO: sort transactions, show the most recent ones on top
    @rpc.request("wallet_account_transaction_history", [account]).then (response) =>
      console.log "--- transactions = ", response.result
      transactions = []
      angular.forEach response.result, (val, key) =>
        blktrx=val.block_num + "." + val.trx_num
        console.log blktrx
        transactions.push
          block_num: ((if (blktrx is "-1.-1") then "Pending" else blktrx))
          #trx_num: Number(key) + 1
          time: new Date(val.received_time*1000)
          amount: val.amount.amount
          from: val.from_account
          to: val.to_account
          memo: val.memo_message
          id: val.trx_id.substring 0, 8
          fee: val.fees
          vote: "N/A"
      transactions


angular.module("app").service("Wallet", ["$q", "$log", "RpcService", "$interval", Wallet])
