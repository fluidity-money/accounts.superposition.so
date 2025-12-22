package graph

func isDryrun(x *bool) bool {
	if x != nil && *x {
		return true
	} else {
		return false
	}
}
