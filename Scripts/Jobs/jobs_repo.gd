class_name JobsRepo extends Resource
## Registry of every job. Jobs are offered in list order.

@export var jobs: Array[JobData] = []


func get_by_id(job_id: StringName) -> JobData:
	for job in jobs:
		if job.id == job_id:
			return job
	return null


## The first job that is not completed yet, or null.
func get_current() -> JobData:
	for job in jobs:
		if not job.completed:
			return job
	return null
