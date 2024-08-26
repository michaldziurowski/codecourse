import RecorderContainer from "./recorder"
import CourseViewerContainer from "./course-viewer"

global css body
	m:0
	box-sizing:border-box

tag ClientApp
	css .container
		bg:cooler8
		w:100%
		h:100vh

	<self>
		<RecorderContainer route="/record/:courseId">
		<CourseViewerContainer.container route="/course/:courseId">

imba.mount <ClientApp>
