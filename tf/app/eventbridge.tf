module "eventbridge" {
    source = "terraform-aws-modules/eventbridge/aws"

    create_bus = false

    rules = {
        crons = {
        description         = "Start cashflow pipeline"
        schedule_expression = "cron(0 10 * * ? *)"
        }
    }

    targets = {
        crons = [
            {
                name = "cashflow-pipeline"
                arn = module.step_functions.state_machine_arn
                attach_role_arn = true
            }
        ]
    }

    sfn_target_arns = [module.step_functions.state_machine_arn]
    attach_sfn_policy = true
}
