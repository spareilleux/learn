fn sdk_kind(name string) string {
	return match name {
		'Microsoft.NET.Sdk' { 'library' }
		'Microsoft.NET.Sdk.Web' { 'web' }
	}
}

fn main() {
	println(sdk_kind('Microsoft.NET.Sdk'))
}
