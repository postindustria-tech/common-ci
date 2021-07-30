# Class contains definition of authorization string.
class Authorization {
	# static [string]$AuthorizationString = "Bearer $Env:SYSTEM_ACCESSTOKEN"
	# When using this script locally, update and use the authorization string with your
	# base 64 PAT as described at
	# https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page#use-a-pat
	# e.g.
	static [string]$AuthorizationString = "Basic [Your base64 encoded PAT]"
}