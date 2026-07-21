function report = attachReqReadiness(report, req_readiness)
%ATTACHREQREADINESS Add REQ-export readiness to a physical report.
%
% The physical report remains available through report.physical_valid.
% The combined report is valid only when both the physical simulation and
% the requested REQ validation sample are valid.

arguments
    report struct
    req_readiness struct
end

validatePhysicalReport(report);
validateReqReadiness(req_readiness);

physical_valid = ...
    logical(report.valid);

req_valid = ...
    logical(req_readiness.valid);

check = struct( ...
    "name", ...
        "req_validation_sample_ready", ...
    "pass", ...
        req_valid, ...
    "value", ...
        double(req_valid), ...
    "threshold", ...
        1, ...
    "message", ...
        string(req_readiness.summary));

report.checks(end + 1, 1) = ...
    check;

report.physical_valid = ...
    physical_valid;

report.valid = ...
    physical_valid && req_valid;

report.req_validation_evaluated = ...
    true;

report.req_validation = ...
    req_readiness;

report.req_validation_reason = ...
    "";

report.summary = ...
    string(report.summary) + ...
    " | " + ...
    string(req_readiness.summary);

end


function validatePhysicalReport(report)

required_fields = [
    "valid"
    "checks"
    "summary"
];

for field_name = required_fields.'
    if ~isfield(report, char(field_name))
        error( ...
            "kwsim:InvalidPhysicalValidationReport", ...
            "Physical report is missing '%s'.", ...
            field_name);
    end
end

if ~isscalar(report.valid)
    error( ...
        "kwsim:InvalidPhysicalValidationReport", ...
        "Physical report.valid must be scalar.");
end

required_check_fields = [
    "name"
    "pass"
    "value"
    "threshold"
    "message"
];

if ~isempty(report.checks)
    available_fields = ...
        string(fieldnames(report.checks));

    if ~all(ismember( ...
            required_check_fields, ...
            available_fields))
        error( ...
            "kwsim:InvalidPhysicalValidationReport", ...
            "Physical report checks do not use the canonical schema.");
    end
end

end


function validateReqReadiness(req_readiness)

required_fields = [
    "valid"
    "checks"
    "summary"
];

for field_name = required_fields.'
    if ~isfield(req_readiness, char(field_name))
        error( ...
            "kwsim:InvalidReqReadinessReport", ...
            "REQ readiness report is missing '%s'.", ...
            field_name);
    end
end

if ~isscalar(req_readiness.valid)
    error( ...
        "kwsim:InvalidReqReadinessReport", ...
        "REQ readiness valid flag must be scalar.");
end

end
