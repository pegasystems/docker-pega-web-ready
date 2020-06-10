pipeline {
  agent any
  stages {
    stage('second') {
      steps {
        echo 'PRs from same repository working!!'
        echo ' PRs from forked repository tested'
        echo ' PRs from forked repository is it creating branch status check? checking on github side again'
        throw new Exception("failing it")
      }
    }
     stage('madhuri') {
      steps {
        echo 'hello there!!'
        echo ' PRs from forked repository is it creating branch status check?'
                echo 'checking PR with integ label'

      }
    }

    stage('kishor') {
      steps {
        echo 'In Kishor stage'
      }
    }
  }
}
