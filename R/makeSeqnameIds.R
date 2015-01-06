makeSeqnameIds <- function(seqnames, X.is.sexchrom=NA)
{
     txt <- "'makeSeqnameIds' is defunct.
           Use 'rankSeqlevels()' in 'GenomeInfoDb' instead." 
    .Defunct("rankSeqlevels", msg=paste(strwrap(txt), collapse="\n"))
    rankSeqlevels(seqnames, X.is.sexchrom=NA)
}

