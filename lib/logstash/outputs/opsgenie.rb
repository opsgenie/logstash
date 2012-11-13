require "logstash/outputs/base"
require "logstash/namespace"
require "net/https"
require "uri"
require 'json'

class LogStash::Outputs::OpsGenie < LogStash::Outputs::Base
	# This output lets you create/update/close alerts 
	# in OpsGenie based on Logstash events

	config_name "opsgenie"
	plugin_status "beta"

	config :customerKey, :validate => :string, :required => true
	config :source, :validate => :string, :required => false, :default => 'Logstash'
	config :recipients, :validate => :string, :required => false, :default => 'all'
	config :opsGenieBaseUrl, :validate => :string, :required => false, :default => 'https://api.opsgenie.com'
	config :createActionUrl, :validate => :string, :required => false, :default =>'/v1/json/alert'
	config :closeActionUrl, :validate => :string, :required => false, :default =>'/v1/json/alert/close'
	config :addNoteActionUrl, :validate => :string, :required => false, :default =>'/v1/json/alert/note'
	config :actionAttribute, :validate => :string, :required => false, :default => 'action'
	config :aliasAttribute, :validate => :string, :required => false, :default => 'alias'
	config :messageAttribute, :validate => :string, :required => false, :default => 'message'
	config :recipientsAttribute, :validate => :string, :required => false, :default => 'recipients'
	config :alertIdAttribute, :validate => :string, :required => false, :default => 'alertId'
	config :noteAttribute, :validate => :string, :required => false, :default => 'note'
	config :sourceAttribute, :validate => :string, :required => false, :default => 'source'
	config :entityAttribute, :validate => :string, :required => false, :default => 'entity'
	config :tagsAttribute, :validate => :string, :required => false, :default => 'tags'
	config :sourceAttribute, :validate => :string, :required => false, :default => 'source'
	config :descriptionAttribute, :validate => :string, :required => false, :default => 'description'
	
	public
	def register
		auth = true
	end # def register

  
	public
	def getValue(event, propName)
		propValue = event.fields[propName];

		if propValue == nil then
			return propValue
		elsif propValue.kind_of?(Array) then
			return propValue[0]
		else
			return propValue;
		end
	end#def getValue
  
	public
	def populateAliasOrId(event, params)
		alertAlias = getValue(event, @aliasAttribute)
		if alertAlias == nil then
			alertId = getValue(event, @alertIdAttribute)
			if !(alertId == nil) then
				params['alertId'] = alertId;
			end
		else
			params['alias'] = alertAlias
		end
	end#def populateAliasOrId
	
	public
	def executePost(uri, params)
		if not uri == nil then
			@logger.info("Executing url #{uri}")
			url = URI(uri)
			http = Net::HTTP.new(url.host, url.port)
			if url.scheme == 'https'
				http.use_ssl = true
				http.verify_mode = OpenSSL::SSL::VERIFY_NONE
			end
			request = Net::HTTP::Post.new(url.path)
			puts "params: #{params.to_json}"
			request.body = params.to_json
			response = http.request(request)
			body = response.body
			body = JSON.parse(body)
			@logger.warn("Executed [#{uri}]. Response:[#{body}]")
		end
	end#def executePost
	
	public
	def receive(event)
		@logger.info("processing #{event}")
		opsGenieAction = getValue(event, @actionAttribute)
		if opsGenieAction then
			params = {:customerKey => @customerKey}
			populateAliasOrId(event, params);	
			if opsGenieAction == 'create' then
				uri = "#{@opsGenieBaseUrl}#{@createActionUrl}"
				params['message'] = event.fields[@messageAttribute]
				params['recipients'] = event.fields[@recipientsAttribute]
				params['entity'] = event.fields[@entityAttribute]
				params['source'] = event.fields[@sourceAttribute]
				params['tags'] = event.fields[@tagsAttribute]
				params['description'] = event.fields[@descriptionAttribute]
			elsif opsGenieAction == 'close' then
				uri = "#{@opsGenieBaseUrl}#{@closeActionUrl}"
			elsif opsGenieAction == 'note' then
				uri = "#{@opsGenieBaseUrl}#{@addNoteActionUrl}"
				params['note'] = event.fields[@noteAttribute]
			else
				@logger.info("No opsgenie action defined")
			end
			executePost(uri, params);
		end
	end # def receive
end

